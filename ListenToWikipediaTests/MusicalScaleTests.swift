import Testing

@testable import ListenToWikipedia

struct MusicalScaleTests {
  // MARK: - notes(root:intervals:octaves:)

  @Test func majorScaleFromC3() {
    // C3 = MIDI 48, major intervals = [2,2,1,2,2,2,1]
    let notes = MusicalScale.notes(
      root: 48,
      intervals: [2, 2, 1, 2, 2, 2, 1],
      octaves: 1
    )
    // C3, D3, E3, F3, G3, A3, B3, C4
    #expect(notes == [48, 50, 52, 53, 55, 57, 59, 60])
  }

  @Test func pentatonicScale() {
    // Major pentatonic from C3: intervals [2, 2, 3, 2, 3]
    let notes = MusicalScale.notes(
      root: 48,
      intervals: [2, 2, 3, 2, 3],
      octaves: 1
    )
    #expect(notes == [48, 50, 52, 55, 57, 60])
  }

  @Test func twoOctaves() {
    let notes = MusicalScale.notes(
      root: 48,
      intervals: [2, 2, 3, 2, 3],
      octaves: 2
    )
    #expect(notes.count == 11)  // root + 5 per octave * 2
    #expect(notes.first == 48)
    #expect(notes.last == 72)
  }

  @Test func stopsAtMidi127() {
    // Start at MIDI 120, should stop before exceeding 127
    let notes = MusicalScale.notes(
      root: 120,
      intervals: [2, 2, 1, 2, 2, 2, 1],
      octaves: 2
    )
    #expect(notes.allSatisfy { $0 <= 127 })
    #expect(notes.first == 120)
  }

  @Test func singleNoteAtHighRoot() {
    // Root at 127 — no room for more notes
    let notes = MusicalScale.notes(
      root: 127,
      intervals: [2, 2, 1, 2, 2, 2, 1],
      octaves: 1
    )
    #expect(notes == [127])
  }

  // MARK: - noteForEdit(changeSize:in:)

  @Test func noteForEditEmptyScale() {
    let note = MusicalScale.noteForEdit(changeSize: 100, in: [])
    #expect(note == nil)
  }

  @Test func noteForEditSingleNoteScale() {
    let note = MusicalScale.noteForEdit(changeSize: 100, in: [60])
    #expect(note == 60)
  }

  @Test func noteForEditLargeEditMapsToLowNote() {
    let scale: [UInt8] = [48, 50, 52, 55, 57, 60]
    let note = MusicalScale.noteForEdit(changeSize: 50000, in: scale)
    // Large edit → lower pitch (closer to root)
    #expect(note == scale.first || note == scale[1])
  }

  @Test func noteForEditSmallEditMapsToHighNote() {
    let scale: [UInt8] = [48, 50, 52, 55, 57, 60]
    let note = MusicalScale.noteForEdit(changeSize: 1, in: scale)
    // Small edit → higher pitch
    #expect(note == scale.last)
  }

  @Test func noteForEditNegativeChangeSize() {
    let scale: [UInt8] = [48, 50, 52, 55, 57, 60]
    let positiveNote = MusicalScale.noteForEdit(changeSize: 100, in: scale)
    let negativeNote = MusicalScale.noteForEdit(changeSize: -100, in: scale)
    // Absolute value is used, so same note
    #expect(positiveNote == negativeNote)
  }

  @Test func noteForEditZeroChangeSize() {
    let scale: [UInt8] = [48, 50, 52, 55, 57, 60]
    let note = MusicalScale.noteForEdit(changeSize: 0, in: scale)
    // Zero → clamped to minBytes=1 → smallest magnitude → highest note
    #expect(note != nil)
    #expect(note == scale.last)
  }

  // MARK: - MusicalKey

  @Test func musicalKeyMidiNote() {
    // C at octave 2 → (2+1)*12 + 0 = 36
    #expect(MusicalKey.c.midiNote(octave: 2) == 36)
    // F# at octave 1 → (1+1)*12 + 6 = 30
    #expect(MusicalKey.fSharp.midiNote(octave: 1) == 30)
  }

  @Test func musicalKeyMidiNoteClamps() {
    // Very high octave should clamp to 127
    let note = MusicalKey.c.midiNote(octave: 10)
    #expect(note <= 127)
  }
}
