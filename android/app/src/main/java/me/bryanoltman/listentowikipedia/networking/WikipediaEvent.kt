package me.bryanoltman.listentowikipedia.networking

import org.json.JSONObject

sealed class WikipediaEvent {
    data class ArticleEdit(
        val language: String,
        val pageTitle: String,
        val changeSize: Int,
        val isAnonymous: Boolean,
        val isBot: Boolean,
        val url: String?,
    ) : WikipediaEvent()

    data class NewUser(
        val language: String,
        val username: String,
    ) : WikipediaEvent()

    companion object {
        fun fromJson(jsonString: String, language: String): WikipediaEvent? {
            val json = try {
                JSONObject(jsonString)
            } catch (_: Exception) {
                return null
            }

            val pageTitle = json.optString("page_title", "")

            if (pageTitle == "Special:Log/newusers") {
                val username = json.optString("user", "") 
                if (username.isEmpty()) return null
                return NewUser(language = language, username = username)
            }

            val ns = json.optString("ns", "")
            if (!ns.equals("main", ignoreCase = true)) return null

            val changeSize = json.optInt("change_size", 0)
            val isAnon = json.optBoolean("is_anon", false)
            val isBot = json.optBoolean("is_bot", false)
            val url = json.optString("url", "").ifEmpty { null }

            return ArticleEdit(
                language = language,
                pageTitle = pageTitle,
                changeSize = changeSize,
                isAnonymous = isAnon,
                isBot = isBot,
                url = url,
            )
        }
    }
}
