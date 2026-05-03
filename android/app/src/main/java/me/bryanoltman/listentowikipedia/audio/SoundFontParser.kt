package me.bryanoltman.listentowikipedia.audio

import android.content.Context
import android.util.Log

/**
 * Parses the preset headers from a SoundFont 2 (.sf2) file.
 *
 * https://en.wikipedia.org/wiki/SoundFont
 * https://www.synthfont.com/SFSPEC21.PDF
 */
object SoundFontParser {
    private const val TAG = "SoundFontParser"

    // SFPresetHeader is exactly 38 bytes:
    //   char     presetName[20]
    //   uint16_t preset          (MIDI program number)
    //   uint16_t bank
    //   uint16_t presetBagNdx
    //   uint32_t library
    //   uint32_t genre
    //   uint32_t morphology
    private const val HEADER_SIZE = 38
    private const val NAME_LENGTH = 20

    // 'phdr' chunk marker bytes
    private val PHDR_MARKER = byteArrayOf(0x70, 0x68, 0x64, 0x72)

    private var cachedInstruments: List<SoundFontInstrument>? = null
    private var cachedInstrumentsByBank: List<Pair<Int, List<SoundFontInstrument>>>? = null

    /**
     * All instruments from the bundled SF2 file, sorted by name. Cached after first call.
     */
    fun bundledInstruments(context: Context): List<SoundFontInstrument> {
        cachedInstruments?.let { return it }
        val instruments = parseBundledSf2(context)
        cachedInstruments = instruments
        cachedInstrumentsByBank = null // invalidate grouped cache
        return instruments
    }

    /**
     * All instruments grouped by bank, sorted by bank then name.
     */
    fun bundledInstrumentsByBank(context: Context): List<Pair<Int, List<SoundFontInstrument>>> {
        cachedInstrumentsByBank?.let { return it }
        val instruments = bundledInstruments(context)
        val grouped = instruments.groupBy { it.bank }
        val result = grouped.keys.sorted().map { bank ->
            bank to grouped[bank]!!
        }
        cachedInstrumentsByBank = result
        return result
    }

    private fun parseBundledSf2(context: Context): List<SoundFontInstrument> {
        val data = try {
            context.assets.open("GeneralUser-GS.sf2").use { it.readBytes() }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read SoundFont from assets", e)
            return emptyList()
        }
        return parsePresets(data)
    }

    /**
     * Parses all preset headers from raw SF2 data.
     */
    fun parsePresets(data: ByteArray): List<SoundFontInstrument> {
        // Locate the 'phdr' chunk marker.
        val markerIndex = findMarker(data, PHDR_MARKER) ?: return emptyList()

        // The 4 bytes after the marker contain the chunk size (little-endian UInt32).
        val sizeStart = markerIndex + 4
        if (sizeStart + 4 > data.size) return emptyList()
        val chunkSize = readUInt32LE(data, sizeStart)

        val presetCount = chunkSize.toInt() / HEADER_SIZE
        val dataStart = sizeStart + 4 // skip 4-byte size field

        val instruments = mutableListOf<SoundFontInstrument>()

        for (i in 0 until presetCount) {
            val offset = dataStart + i * HEADER_SIZE
            if (offset + HEADER_SIZE > data.size) break

            // Read the null-terminated preset name from the first 20 bytes.
            val nameBytes = data.copyOfRange(offset, offset + NAME_LENGTH)
            val nullIndex = nameBytes.indexOf(0)
            val name = if (nullIndex >= 0) {
                String(nameBytes, 0, nullIndex, Charsets.ISO_8859_1)
            } else {
                String(nameBytes, Charsets.ISO_8859_1)
            }

            // SF2 ends with a sentinel record named "EOP" (End Of Presets).
            if (name == "EOP") continue

            // Bytes 20-21: program (MIDI preset number), little-endian UInt16.
            val program = readUInt16LE(data, offset + 20)

            // Bytes 22-23: bank, little-endian UInt16.
            val bank = readUInt16LE(data, offset + 22)

            instruments.add(
                SoundFontInstrument(
                    name = name.trim(),
                    bank = bank,
                    program = program and 0x7F,
                )
            )
        }

        return instruments.sortedBy { it.name }
    }

    private fun findMarker(data: ByteArray, marker: ByteArray): Int? {
        outer@ for (i in 0..data.size - marker.size) {
            for (j in marker.indices) {
                if (data[i + j] != marker[j]) continue@outer
            }
            return i
        }
        return null
    }

    private fun readUInt16LE(data: ByteArray, offset: Int): Int {
        return (data[offset].toInt() and 0xFF) or
            ((data[offset + 1].toInt() and 0xFF) shl 8)
    }

    private fun readUInt32LE(data: ByteArray, offset: Int): Long {
        return (data[offset].toLong() and 0xFF) or
            ((data[offset + 1].toLong() and 0xFF) shl 8) or
            ((data[offset + 2].toLong() and 0xFF) shl 16) or
            ((data[offset + 3].toLong() and 0xFF) shl 24)
    }
}
