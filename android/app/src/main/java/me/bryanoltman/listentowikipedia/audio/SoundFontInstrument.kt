package me.bryanoltman.listentowikipedia.audio

/**
 * Identifies an SF2 preset by its bank and program number.
 */
data class InstrumentId(val bank: Int, val program: Int)

/**
 * A single preset parsed from a SoundFont 2 file.
 */
data class SoundFontInstrument(
    val name: String,
    val bank: Int,
    val program: Int,
) {
    val id: InstrumentId get() = InstrumentId(bank, program)
}
