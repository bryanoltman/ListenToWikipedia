package me.bryanoltman.listentowikipedia.audio

enum class EditSoundType(val displayName: String) {
    ADDITION("Addition"),
    SUBTRACTION("Subtraction"),
    NEW_USER("New User");

    /** MIDI channel used by this type in the SoundFont synthesizer (0, 1, 2). */
    val midiChannel: Int get() = ordinal

    /**
     * Default SF2 presets from the bundled GeneralUser-GS.sf2 (all bank 0).
     * These match the instrument families used by listen.hatnote.com:
     *   - Program 8  "Celeste"  — the celesta sounds used for additions
     *   - Program 7  "Clavinet" — the clav sounds used for subtractions
     *   - Program 89 "Warm Pad" — approximates the swell sounds for new-user events
     */
    val defaultInstrumentId: InstrumentId
        get() = when (this) {
            ADDITION -> InstrumentId(bank = 0, program = 8)
            SUBTRACTION -> InstrumentId(bank = 0, program = 7)
            NEW_USER -> InstrumentId(bank = 0, program = 89)
        }
}
