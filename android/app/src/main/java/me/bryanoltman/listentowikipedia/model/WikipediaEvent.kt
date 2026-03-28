package me.bryanoltman.listentowikipedia.model

data class WikipediaArticleEdit(
    val language: String,
    val pageTitle: String,
    val changeSize: Int,
    val isAnonymous: Boolean,
    val isBot: Boolean,
    val url: String?
)

data class WikipediaNewUser(val language: String, val username: String)

sealed class WikipediaEvent {
    data class ArticleEdit(val edit: WikipediaArticleEdit) : WikipediaEvent()
    data class NewUser(val user: WikipediaNewUser) : WikipediaEvent()
}
