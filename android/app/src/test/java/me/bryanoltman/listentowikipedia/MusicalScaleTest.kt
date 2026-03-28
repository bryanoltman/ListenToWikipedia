package me.bryanoltman.listentowikipedia

import me.bryanoltman.listentowikipedia.model.HeptatonicMode
import me.bryanoltman.listentowikipedia.model.MusicalKey
import me.bryanoltman.listentowikipedia.model.MusicalScale
import me.bryanoltman.listentowikipedia.model.PentatonicMode
import org.junit.Assert.*
import org.junit.Test

class MusicalScaleTest {

    // --- notes() ---

    @Test
    fun `notes generates correct pentatonic scale from C4`() {
        // C4 = MIDI 60, Major Pentatonic intervals = [2, 2, 3, 2, 3]
        val root = MusicalKey.C.midiNote(3) // (3+1)*12 + 0 = 48
        val notes = MusicalScale.notes(root, PentatonicMode.MAJOR_PENTATONIC.intervals, octaves = 1)
        // Expected: 48, 50, 52, 55, 57, 60
        assertEquals(listOf(48, 50, 52, 55, 57, 60), notes)
    }

    @Test
    fun `notes generates correct dorian scale from D3`() {
        val root = MusicalKey.D.midiNote(2) // (2+1)*12 + 2 = 38
        val notes = MusicalScale.notes(root, HeptatonicMode.DORIAN.intervals, octaves = 1)
        // Dorian intervals: 2,1,2,2,2,1,2 → 38,40,41,43,45,47,48,50
        assertEquals(listOf(38, 40, 41, 43, 45, 47, 48, 50), notes)
    }

    @Test
    fun `notes with 2 octaves doubles the pattern`() {
        val root = MusicalKey.C.midiNote(3) // 48
        val notes = MusicalScale.notes(root, PentatonicMode.MAJOR_PENTATONIC.intervals, octaves = 2)
        // 2 octaves: 48, +2, +2, +3, +2, +3, +2, +2, +3, +2, +3
        assertEquals(11, notes.size)
        assertEquals(48, notes.first())
        assertEquals(72, notes.last())
    }

    @Test
    fun `notes stops at MIDI 127`() {
        val root = MusicalKey.C.midiNote(9) // (9+1)*12 = 120
        val notes = MusicalScale.notes(root, HeptatonicMode.IONIAN.intervals, octaves = 2)
        // Should stop before exceeding 127
        assertTrue(notes.all { it <= 127 })
        assertTrue(notes.size < 15) // can't fit 2 full octaves
    }

    @Test
    fun `notes with empty intervals returns just root`() {
        val notes = MusicalScale.notes(60, emptyList(), octaves = 2)
        assertEquals(listOf(60), notes)
    }

    // --- noteForEdit() ---

    @Test
    fun `noteForEdit returns root for very large edit`() {
        val scale = listOf(48, 50, 52, 55, 57, 60)
        // 100000 bytes → normalized = log(100000)/log(100000) = 1.0 → pos = 0 → root
        val note = MusicalScale.noteForEdit(100000, scale)
        assertEquals(48, note)
    }

    @Test
    fun `noteForEdit returns highest note for smallest edit`() {
        val scale = listOf(48, 50, 52, 55, 57, 60)
        // 1 byte → normalized = log(1)/log(100000) = 0 → pos = 5 → last
        val note = MusicalScale.noteForEdit(1, scale)
        assertEquals(60, note)
    }

    @Test
    fun `noteForEdit handles negative change size`() {
        val scale = listOf(48, 50, 52, 55, 57, 60)
        // -500 → abs = 500
        val note = MusicalScale.noteForEdit(-500, scale)
        assertNotNull(note)
        assertTrue(note!! in scale)
    }

    @Test
    fun `noteForEdit returns null for empty scale`() {
        assertNull(MusicalScale.noteForEdit(100, emptyList()))
    }

    @Test
    fun `noteForEdit clamps magnitude above 100000`() {
        val scale = listOf(48, 50, 52, 55, 57, 60)
        // 999999 → clamped to 100000 → root
        val note = MusicalScale.noteForEdit(999999, scale)
        assertEquals(48, note)
    }

    @Test
    fun `noteForEdit clamps magnitude below 1`() {
        val scale = listOf(48, 50, 52, 55, 57, 60)
        // 0 → clamped to 1 → last note
        val note = MusicalScale.noteForEdit(0, scale)
        assertEquals(60, note)
    }

    // --- MusicalKey ---

    @Test
    fun `MusicalKey semitones are 0 through 11`() {
        val semitones = MusicalKey.entries.map { it.semitone }
        assertEquals((0..11).toList(), semitones)
    }

    @Test
    fun `MusicalKey midiNote clamps to 0-127`() {
        assertEquals(0, MusicalKey.C.midiNote(-1)) // would be 0
        assertEquals(127, MusicalKey.B.midiNote(10)) // would be 143, clamped
    }

    @Test
    fun `MusicalKey C at octave 4 is MIDI 60`() {
        assertEquals(60, MusicalKey.C.midiNote(4))
    }

    // --- Mode intervals ---

    @Test
    fun `all heptatonic modes have 7 intervals summing to 12`() {
        for (mode in HeptatonicMode.entries) {
            assertEquals("${mode.name} should have 7 intervals", 7, mode.intervals.size)
            assertEquals("${mode.name} intervals should sum to 12", 12, mode.intervals.sum())
        }
    }

    @Test
    fun `all pentatonic modes have 5 intervals summing to 12`() {
        for (mode in PentatonicMode.entries) {
            assertEquals("${mode.name} should have 5 intervals", 5, mode.intervals.size)
            assertEquals("${mode.name} intervals should sum to 12", 12, mode.intervals.sum())
        }
    }
}
