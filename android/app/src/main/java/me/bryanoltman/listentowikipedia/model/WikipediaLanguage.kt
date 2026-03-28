package me.bryanoltman.listentowikipedia.model

data class WikipediaLanguage(val name: String, val code: String) {
    companion object {
        val all: List<WikipediaLanguage> = listOf(
            WikipediaLanguage("Arabic", "ar"),
            WikipediaLanguage("Assamese", "as"),
            WikipediaLanguage("Belarusian", "be"),
            WikipediaLanguage("Bengali", "bn"),
            WikipediaLanguage("Bulgarian", "bg"),
            WikipediaLanguage("Chinese", "zh"),
            WikipediaLanguage("Dutch", "nl"),
            WikipediaLanguage("English", "en"),
            WikipediaLanguage("Farsi", "fa"),
            WikipediaLanguage("French", "fr"),
            WikipediaLanguage("German", "de"),
            WikipediaLanguage("Gujarati", "gu"),
            WikipediaLanguage("Hebrew", "he"),
            WikipediaLanguage("Hindi", "hi"),
            WikipediaLanguage("Indonesian", "id"),
            WikipediaLanguage("Italian", "it"),
            WikipediaLanguage("Japanese", "ja"),
            WikipediaLanguage("Kannada", "kn"),
            WikipediaLanguage("Macedonian", "mk"),
            WikipediaLanguage("Malayalam", "ml"),
            WikipediaLanguage("Oriya", "or"),
            WikipediaLanguage("Polish", "pl"),
            WikipediaLanguage("Punjabi", "pa"),
            WikipediaLanguage("Russian", "ru"),
            WikipediaLanguage("Sanskrit", "sa"),
            WikipediaLanguage("Serbian", "sr"),
            WikipediaLanguage("Spanish", "es"),
            WikipediaLanguage("Swedish", "sv"),
            WikipediaLanguage("Tamil", "ta"),
            WikipediaLanguage("Telugu", "te"),
            WikipediaLanguage("Ukrainian", "uk"),
            WikipediaLanguage("Marathi", "mr"),
        )
    }
}
