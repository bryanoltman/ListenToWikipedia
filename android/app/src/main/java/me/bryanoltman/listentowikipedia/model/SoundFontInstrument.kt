package me.bryanoltman.listentowikipedia.model

/// Identifies an instrument by its bank and program number.
data class InstrumentId(val bank: Int, val program: Int)

data class SoundFontInstrument(val name: String, val bank: Int, val program: Int) {
    val id: InstrumentId get() = InstrumentId(bank = bank, program = program)
}
