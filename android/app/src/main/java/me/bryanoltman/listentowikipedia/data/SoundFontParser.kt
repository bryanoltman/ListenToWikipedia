package me.bryanoltman.listentowikipedia.data

import me.bryanoltman.listentowikipedia.model.SoundFontInstrument
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

object SoundFontParser {
    private const val HEADER_SIZE = 38
    private const val NAME_LENGTH = 20

    /**
     * Parses preset headers from an SF2 input stream.
     * Returns instruments sorted by name.
     */
    fun instruments(inputStream: InputStream): List<SoundFontInstrument> {
        val data = inputStream.readBytes()
        return parseInstruments(data)
    }

    private fun parseInstruments(data: ByteArray): List<SoundFontInstrument> {
        // Locate the 'phdr' chunk marker: bytes 0x70, 0x68, 0x64, 0x72
        val marker = byteArrayOf(0x70, 0x68, 0x64, 0x72)
        val markerIndex = findMarker(data, marker) ?: return emptyList()

        // The 4 bytes after the marker contain the chunk size (little-endian UInt32)
        val sizeStart = markerIndex + 4
        if (sizeStart + 4 > data.size) return emptyList()

        val buf = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        val chunkSize = buf.getInt(sizeStart).toLong() and 0xFFFFFFFFL
        val presetCount = (chunkSize / HEADER_SIZE).toInt()
        val dataStart = sizeStart + 4 // skip 4-byte size field

        val instruments = mutableListOf<SoundFontInstrument>()

        for (i in 0 until presetCount) {
            val offset = dataStart + i * HEADER_SIZE
            if (offset + HEADER_SIZE > data.size) break

            // Read the null-terminated preset name from the first 20 bytes
            val nameBytes = data.copyOfRange(offset, offset + NAME_LENGTH)
            val nullIndex = nameBytes.indexOf(0)
            val name = if (nullIndex >= 0) {
                String(nameBytes, 0, nullIndex, Charsets.US_ASCII)
            } else {
                String(nameBytes, Charsets.US_ASCII)
            }

            // Sentinel record "EOP" marks end of presets
            if (name == "EOP") continue

            // Bytes 20-21: program (MIDI preset number), little-endian UInt16
            val program = buf.getShort(offset + 20).toInt() and 0x7F
            // Bytes 22-23: bank, little-endian UInt16
            val bank = buf.getShort(offset + 22).toInt() and 0xFFFF

            instruments.add(SoundFontInstrument(name = name, bank = bank, program = program))
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
}
