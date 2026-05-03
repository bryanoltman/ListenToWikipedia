package me.bryanoltman.listentowikipedia.model

data class WikipediaLanguage(val name: String, val code: String)

object WikipediaLanguages {
    val arabic = WikipediaLanguage("Arabic", "ar")
    val assamese = WikipediaLanguage("Assamese", "as")
    val belarusian = WikipediaLanguage("Belarusian", "be")
    val bengali = WikipediaLanguage("Bengali", "bn")
    val bulgarian = WikipediaLanguage("Bulgarian", "bg")
    val chinese = WikipediaLanguage("Chinese", "zh")
    val dutch = WikipediaLanguage("Dutch", "nl")
    val english = WikipediaLanguage("English", "en")
    val farsi = WikipediaLanguage("Farsi", "fa")
    val french = WikipediaLanguage("French", "fr")
    val german = WikipediaLanguage("German", "de")
    val gujarati = WikipediaLanguage("Gujarati", "gu")
    val hebrew = WikipediaLanguage("Hebrew", "he")
    val hindi = WikipediaLanguage("Hindi", "hi")
    val indonesian = WikipediaLanguage("Indonesian", "id")
    val italian = WikipediaLanguage("Italian", "it")
    val japanese = WikipediaLanguage("Japanese", "ja")
    val kannada = WikipediaLanguage("Kannada", "kn")
    val macedonian = WikipediaLanguage("Macedonian", "mk")
    val malayalam = WikipediaLanguage("Malayalam", "ml")
    val marathi = WikipediaLanguage("Marathi", "mr")
    val oriya = WikipediaLanguage("Oriya", "or")
    val polish = WikipediaLanguage("Polish", "pl")
    val punjabi = WikipediaLanguage("Punjabi", "pa")
    val russian = WikipediaLanguage("Russian", "ru")
    val sanskrit = WikipediaLanguage("Sanskrit", "sa")
    val serbian = WikipediaLanguage("Serbian", "sr")
    val spanish = WikipediaLanguage("Spanish", "es")
    val swedish = WikipediaLanguage("Swedish", "sv")
    val tamil = WikipediaLanguage("Tamil", "ta")
    val telugu = WikipediaLanguage("Telugu", "te")
    val ukrainian = WikipediaLanguage("Ukrainian", "uk")

    val all: List<WikipediaLanguage> = listOf(
        arabic,
        assamese,
        belarusian,
        bengali,
        bulgarian,
        chinese,
        dutch,
        english,
        farsi,
        french,
        german,
        gujarati,
        hebrew,
        hindi,
        indonesian,
        italian,
        japanese,
        kannada,
        macedonian,
        malayalam,
        marathi,
        oriya,
        polish,
        punjabi,
        russian,
        sanskrit,
        serbian,
        spanish,
        swedish,
        tamil,
        telugu,
        ukrainian
    )
}
