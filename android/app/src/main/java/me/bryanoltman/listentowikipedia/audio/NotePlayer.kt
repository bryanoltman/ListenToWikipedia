package me.bryanoltman.listentowikipedia.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log
import io.github.lemcoder.mikrosoundfont.MikroSoundFont
import io.github.lemcoder.mikrosoundfont.SoundFont
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Plays musical notes using the bundled SoundFont file.
 *
 * Loads `GeneralUser-GS.sf2` from assets via [MikroSoundFont] (TinySoundFont)
 * and renders audio into a streaming [AudioTrack]. Each [EditSoundType] is
 * assigned a MIDI channel so different event types can play different
 * instruments simultaneously.
 *
 * A dedicated render thread continuously calls [SoundFont.renderFloat] and
 * writes PCM data to the AudioTrack. Note-on/off events mutate the SoundFont
 * state under a shared lock.
 */
class NotePlayer(context: Context) {

    private val soundFont: SoundFont
    private var audioTrack: AudioTrack? = null
    private var renderThread: Thread? = null
    @Volatile private var isRunning = false

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val lock = Any()

    init {
        val sfBytes = context.assets.open(SF2_ASSET).use { it.readBytes() }
        soundFont = MikroSoundFont.load(sfBytes)
        soundFont.setOutput(SoundFont.OutputMode.MONO, SAMPLE_RATE, GLOBAL_GAIN_DB)
        soundFont.setMaxVoices(MAX_VOICES)
        startAudioLoop()
    }

    /**
     * Switches the instrument for the given [EditSoundType] to the SF2 preset
     * identified by [bank] and [program].
     */
    fun loadProgram(type: EditSoundType, bank: Int, program: Int) {
        synchronized(lock) {
            soundFont.setBankPreset(type.midiChannel, bank, program)
        }
    }

    /**
     * Plays a MIDI note on the channel for [type], stopping it after [NOTE_DURATION_MS].
     * If the same note is already sounding on that channel, the SoundFont will
     * layer a new voice (matching iOS behavior).
     */
    fun play(note: Int, velocity: Int = 100, type: EditSoundType) {
        val channel = type.midiChannel
        synchronized(lock) {
            soundFont.channels[channel].noteOn(note, velocity / 127f)
        }

        scope.launch {
            delay(NOTE_DURATION_MS)
            synchronized(lock) {
                soundFont.channels[channel].noteOff(note)
            }
        }
    }

    /** Stops all active notes immediately. */
    fun stop() {
        synchronized(lock) {
            soundFont.noteOffAll()
        }
    }

    /** Stops all notes, tears down the render thread, and releases the AudioTrack. */
    fun release() {
        isRunning = false
        renderThread?.join(1000)
        scope.cancel()
        audioTrack?.let { releaseTrack(it) }
        audioTrack = null
    }

    // -------------------------------------------------------------------

    private fun startAudioLoop() {
        val minBuf = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val track = try {
            AudioTrack(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
                AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
                minBuf,
                AudioTrack.MODE_STREAM,
                AudioManager.AUDIO_SESSION_ID_GENERATE,
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create AudioTrack", e)
            return
        }
        audioTrack = track
        track.play()

        isRunning = true
        renderThread = Thread({
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
            val shortBuf = ShortArray(CHUNK_SAMPLES)

            while (isRunning) {
                val floatBuf: FloatArray
                synchronized(lock) {
                    floatBuf = soundFont.renderFloat(CHUNK_SAMPLES, 1, false)
                }
                for (i in floatBuf.indices) {
                    shortBuf[i] = (floatBuf[i] * Short.MAX_VALUE)
                        .toInt()
                        .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                        .toShort()
                }
                val written = track.write(shortBuf, 0, CHUNK_SAMPLES)
                if (written < 0) {
                    Log.e(TAG, "AudioTrack.write error: $written")
                    break
                }
            }
        }, "SoundFontRenderer").apply {
            isDaemon = true
            start()
        }
    }

    private fun releaseTrack(track: AudioTrack) {
        try {
            track.stop()
        } catch (_: IllegalStateException) {
            // Not initialized or already stopped
        }
        track.release()
    }

    companion object {
        private const val TAG = "NotePlayer"
        private const val SF2_ASSET = "GeneralUser-GS.sf2"
        private const val SAMPLE_RATE = 44100
        private const val GLOBAL_GAIN_DB = -3f
        private const val NOTE_DURATION_MS = 5000L
        private const val MAX_VOICES = 64

        /** ~20ms render chunks at 44.1kHz */
        private const val CHUNK_SAMPLES = SAMPLE_RATE / 50
    }
}
