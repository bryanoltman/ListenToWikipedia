package me.bryanoltman.listentowikipedia.network

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import me.bryanoltman.listentowikipedia.model.WikipediaArticleEdit
import me.bryanoltman.listentowikipedia.model.WikipediaEvent
import me.bryanoltman.listentowikipedia.model.WikipediaNewUser
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class WikipediaWebSocketService {
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS) // no timeout for websocket
        .build()

    private val sockets = mutableMapOf<String, WebSocket>()

    private val _connectedLanguages = MutableStateFlow<Set<String>>(emptySet())
    val connectedLanguages: StateFlow<Set<String>> = _connectedLanguages.asStateFlow()

    private val _events = MutableSharedFlow<WikipediaEvent>(extraBufferCapacity = 64)
    val events: SharedFlow<WikipediaEvent> = _events.asSharedFlow()

    fun connect(language: String) {
        if (sockets.containsKey(language)) return
        val request = Request.Builder()
            .url("wss://wikimon.hatnote.com/v2/$language")
            .build()
        val ws = client.newWebSocket(request, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                parse(text, language)?.let { _events.tryEmit(it) }
            }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                sockets.remove(language)
                _connectedLanguages.value = _connectedLanguages.value - language
            }
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                sockets.remove(language)
                _connectedLanguages.value = _connectedLanguages.value - language
            }
        })
        sockets[language] = ws
        _connectedLanguages.value = _connectedLanguages.value + language
    }

    fun disconnect(language: String) {
        sockets.remove(language)?.close(1000, null)
        _connectedLanguages.value = _connectedLanguages.value - language
    }

    fun disconnectAll() {
        sockets.keys.toList().forEach { disconnect(it) }
    }

    private fun parse(text: String, language: String): WikipediaEvent? {
        val json = try { JSONObject(text) } catch (e: Exception) { return null }
        val pageTitle = json.optString("page_title", "")

        // New-user registration event
        if (pageTitle == "Special:Log/newusers") {
            val username = json.optString("user", "").ifEmpty { return null }
            return WikipediaEvent.NewUser(WikipediaNewUser(language, username))
        }

        // Article edit — main namespace only
        val ns = json.optString("ns", "")
        if (!ns.equals("main", ignoreCase = true)) return null

        val changeSize = json.optInt("change_size", 0)
        val isAnon = json.optBoolean("is_anon", false)
        val isBot = json.optBoolean("is_bot", false)
        val url = json.optString("url", "").ifEmpty { null }

        return WikipediaEvent.ArticleEdit(
            WikipediaArticleEdit(
                language = language,
                pageTitle = pageTitle,
                changeSize = changeSize,
                isAnonymous = isAnon,
                isBot = isBot,
                url = url
            )
        )
    }
}
