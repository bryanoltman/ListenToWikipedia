package me.bryanoltman.listentowikipedia.audio

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.pow
import kotlin.math.sin

/**
 * Synthesizes and plays musical tones for Wikipedia edit events.
 *
 * Uses [AudioTrack] with generated PCM waveforms instead of MIDI, so it works
 * on every Android device without requiring a platform synthesizer.
 *
 * Each [EditSoundType] gets a distinct timbre:
 * - Addition (Celesta-like): sine + quiet octave harmonic, fast attack, moderate decay
 * - Subtraction (Clavinet-like): sine + 3rd harmonic, fast attack, short decay
 * - New User (Warm Pad-like): pure sine, slow attack, long decay
 *
 * The coroutine that launches playback is the sole owner of its [AudioTrack].
 * Cancelling the coroutine triggers its `finally` block, which stops and
 * releases the track. No other code path touches the track.
 */
class NotePlayer {

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val activeNotes = ConcurrentHashMap<NoteKey, Job>()

    /**
     * Program numbers are unused for tone generation but stored so the settings
     * UI can still display the selected instrument name.
     */
    fun loadProgram(type: EditSoundType, program: Int) {
        // No-op: tone generation doesn't use GM programs for playback.
        // The program selection is preserved in AppSettings for UI display.
    }

    fun play(note: Int, velocity: Int = 100, type: EditSoundType) {
        if (activeNotes.size >= MAX_SIMULTANEOUS) return

        val key = NoteKey(type, note)
        activeNotes.remove(key)?.cancel()

        val frequency = 440.0 * 2.0.pow((note - 69) / 12.0)
        val amplitude = (velocity / 127.0) * MASTER_VOLUME

        activeNotes[key] = scope.launch {
            val track = buildTrack(frequency, amplitude, type) ?: return@launch
            track.play()
            try {
                delay(TONE_DURATION_MS)
            } finally {
                releaseTrack(track)
                activeNotes.remove(key)
            }
        }
    }

    fun stop() {
        for ((_, job) in activeNotes) {
            job.cancel()
        }
        activeNotes.clear()
    }

    fun release() {
        stop()
        scope.cancel()
    }

    // -------------------------------------------------------------------

    private fun releaseTrack(track: AudioTrack) {
        try {
            track.stop()
        } catch (_: IllegalStateException) {
            // Not initialized or already stopped
        }
        track.release()
    }

    private fun buildTrack(
        frequency: Double,
        amplitude: Double,
        type: EditSoundType
    ): AudioTrack? {
        val totalSamples = (SAMPLE_RATE * TONE_DURATION_MS / 1000).toInt()
        val samples = ShortArray(totalSamples)

        val attackSeconds = when (type) {
            EditSoundType.ADDITION -> 0.005
            EditSoundType.SUBTRACTION -> 0.002
            EditSoundType.NEW_USER -> 0.08
        }
        val decayTau = when (type) {
            EditSoundType.ADDITION -> 1.2
            EditSoundType.SUBTRACTION -> 0.6
            EditSoundType.NEW_USER -> 1.6
        }
        // Harmonic mix: (harmonicMultiplier, relativeAmplitude)
        val harmonics: List<Pair<Double, Double>> = when (type) {
            EditSoundType.ADDITION -> listOf(1.0 to 1.0, 2.0 to 0.15)
            EditSoundType.SUBTRACTION -> listOf(1.0 to 1.0, 3.0 to 0.10)
            EditSoundType.NEW_USER -> listOf(1.0 to 1.0)
        }

        val attackSamples = (attackSeconds * SAMPLE_RATE).toInt().coerceAtLeast(1)

        for (i in 0 until totalSamples) {
            val t = i.toDouble() / SAMPLE_RATE

            var wave = 0.0
            for ((mult, amp) in harmonics) {
                wave += amp * sin(2.0 * PI * frequency * mult * t)
            }

            val env = if (i < attackSamples) {
                i.toDouble() / attackSamples
            } else {
                exp(-(t - attackSeconds) / decayTau)
            }

            val value = (wave * amplitude * env * Short.MAX_VALUE)
                .toInt()
                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
            samples[i] = value.toShort()
        }

        val bufferSizeBytes = totalSamples * 2 // 16-bit PCM
        return try {
            val track = AudioTrack(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
                AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
                bufferSizeBytes,
                AudioTrack.MODE_STATIC,
                AudioManager.AUDIO_SESSION_ID_GENERATE
            )
            track.write(samples, 0, totalSamples)
            track
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create AudioTrack", e)
            null
        }
    }

    private data class NoteKey(val type: EditSoundType, val note: Int)

    companion object {
        private const val TAG = "NotePlayer"
        private const val SAMPLE_RATE = 22050
        private const val TONE_DURATION_MS = 2000L
        private const val MAX_SIMULTANEOUS = 10
        private const val MASTER_VOLUME = 0.25
    }
}
