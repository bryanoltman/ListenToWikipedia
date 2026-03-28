package me.bryanoltman.listentowikipedia.audio

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import me.bryanoltman.listentowikipedia.model.EditSoundType
import org.billthefarmer.mididriver.MidiDriver

/** Uniquely identifies a sounding note across channels. */
data class NoteKey(val type: EditSoundType, val note: Int)

/**
 * Plays MIDI notes using the Sonivox/EAS synthesizer via mididriver.
 *
 * Each [EditSoundType] is assigned its own MIDI channel (by ordinal), so
 * three independent instruments can sound simultaneously.
 */
class NotePlayer {
    private val midi = MidiDriver.getInstance()
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var started = false

    /** Active notes mapped to their auto-off timeout jobs. */
    private val activeNotes = mutableMapOf<NoteKey, Job>()

    /**
     * Starts the MIDI driver and loads an instrument on each channel.
     *
     * @param programs per-type GM program numbers. Missing entries are
     *                 silently skipped (the channel keeps its default).
     */
    fun start(programs: Map<EditSoundType, Int>) {
        if (started) return
        midi.start()
        started = true
        for ((type, program) in programs) {
            loadInstrument(program, type)
        }
    }

    /**
     * Sends a Program Change on the channel for [type].
     */
    fun loadInstrument(program: Int, type: EditSoundType) {
        if (!started) return
        val channel = type.ordinal
        midi.write(byteArrayOf((0xC0 + channel).toByte(), program.toByte()))
    }

    /**
     * Plays a MIDI note on the channel for [type], auto-stopping after 5 s.
     *
     * If the same note is already sounding on that channel (re-attack), the
     * previous voice is stopped first to prevent layered duplicates.
     */
    fun play(note: Int, velocity: Int = 100, type: EditSoundType) {
        if (!started) return
        val channel = type.ordinal
        val key = NoteKey(type, note)

        // Re-attack: cancel pending timeout and send Note Off immediately.
        activeNotes.remove(key)?.let { job ->
            job.cancel()
            sendNoteOff(channel, note)
        }

        // Note On
        midi.write(byteArrayOf((0x90 + channel).toByte(), note.toByte(), velocity.toByte()))

        // Schedule automatic Note Off after 5 seconds.
        val job = scope.launch {
            delay(5000)
            sendNoteOff(channel, note)
            activeNotes.remove(key)
        }
        activeNotes[key] = job
    }

    /**
     * Stops all sounding notes and shuts down the MIDI driver.
     */
    fun stop() {
        if (!started) return
        // Cancel all pending timeouts and silence every active note.
        for ((key, job) in activeNotes) {
            job.cancel()
            sendNoteOff(key.type.ordinal, key.note)
        }
        activeNotes.clear()
        midi.stop()
        started = false
    }

    private fun sendNoteOff(channel: Int, note: Int) {
        midi.write(byteArrayOf((0x80 + channel).toByte(), note.toByte(), 0))
    }
}
