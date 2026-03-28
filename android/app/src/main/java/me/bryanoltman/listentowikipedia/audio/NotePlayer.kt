package me.bryanoltman.listentowikipedia.audio

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.billthefarmer.mididriver.MidiDriver

/**
 * Plays MIDI notes using the Sonivox/EAS synthesizer via mididriver.
 * Uses General MIDI instruments (program numbers match GM spec).
 */
class NotePlayer {
    private val midi = MidiDriver.getInstance()
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var started = false

    fun start() {
        if (!started) {
            midi.start()
            started = true
            // Default to Acoustic Guitar (Nylon), program 24
            loadInstrument(24)
        }
    }

    /**
     * Switches to the instrument identified by the GM program number.
     */
    fun loadInstrument(program: Int) {
        if (!started) return
        // Program Change on channel 0: [0xC0, program]
        midi.write(byteArrayOf(0xC0.toByte(), program.toByte()))
    }

    /**
     * Plays a MIDI note, then stops it after 5 seconds.
     */
    fun play(note: Int, velocity: Int = 100) {
        if (!started) return
        // Note On channel 0: [0x90, note, velocity]
        midi.write(byteArrayOf(0x90.toByte(), note.toByte(), velocity.toByte()))
        scope.launch {
            delay(5000)
            // Note Off channel 0: [0x80, note, 0]
            midi.write(byteArrayOf(0x80.toByte(), note.toByte(), 0))
        }
    }

    fun stop() {
        if (started) {
            midi.stop()
            started = false
        }
    }
}
