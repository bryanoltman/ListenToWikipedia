package me.bryanoltman.listentowikipedia

import me.bryanoltman.listentowikipedia.model.WikipediaLanguage
import org.junit.Assert.*
import org.junit.Test

class WikipediaLanguageTest {

    @Test
    fun `language list has 32 entries`() {
        assertEquals(32, WikipediaLanguage.all.size)
    }

    @Test
    fun `all language codes are unique`() {
        val codes = WikipediaLanguage.all.map { it.code }
        assertEquals(codes.size, codes.toSet().size)
    }

    @Test
    fun `English is present with code en`() {
        val en = WikipediaLanguage.all.find { it.code == "en" }
        assertNotNull("English should be in the language list", en)
        assertEquals("English", en!!.name)
    }

    @Test
    fun `Marathi is present with code mr (not Western Mari)`() {
        val mr = WikipediaLanguage.all.find { it.code == "mr" }
        assertNotNull("Code 'mr' should be in the language list", mr)
        assertEquals("Marathi", mr!!.name)
    }

    @Test
    fun `Western Mari does not appear in any entry`() {
        val western = WikipediaLanguage.all.find { it.name == "Western Mari" }
        assertNull("'Western Mari' should not be in the language list", western)
    }

    @Test
    fun `all expected language codes are present`() {
        val expectedCodes = setOf(
            "ar", "as", "be", "bn", "bg", "zh", "nl", "en", "fa", "fr",
            "de", "gu", "he", "hi", "id", "it", "ja", "kn", "mk", "ml",
            "or", "pl", "pa", "ru", "sa", "sr", "es", "sv", "ta", "te",
            "uk", "mr"
        )
        val actualCodes = WikipediaLanguage.all.map { it.code }.toSet()
        assertEquals(expectedCodes, actualCodes)
    }
}
