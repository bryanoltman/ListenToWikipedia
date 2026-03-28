package me.bryanoltman.listentowikipedia.network

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
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

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Guards sockets, reconnectJobs, and backoffDelays
    private val lock = Any()
    private val sockets = mutableMapOf<String, WebSocket>()
    private val reconnectJobs = mutableMapOf<String, Job>()
    private val backoffDelays = mutableMapOf<String, Long>()

    private val _connectedLanguages = MutableStateFlow<Set<String>>(emptySet())
    val connectedLanguages: StateFlow<Set<String>> = _connectedLanguages.asStateFlow()

    private val _events = MutableSharedFlow<WikipediaEvent>(extraBufferCapacity = 64)
    val events: SharedFlow<WikipediaEvent> = _events.asSharedFlow()

    companion object {
        private const val INITIAL_BACKOFF_MS = 1_000L
        private const val MAX_BACKOFF_MS = 30_000L
        private const val NORMAL_CLOSURE = 1000
    }

    fun connect(language: String) {
        synchronized(lock) {
            if (sockets.containsKey(language)) return
            backoffDelays[language] = INITIAL_BACKOFF_MS
        }

        val request = Request.Builder()
            .url("wss://wikimon.hatnote.com/v2/$language")
            .build()

        val ws = client.newWebSocket(request, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                synchronized(lock) {
                    backoffDelays[language] = INITIAL_BACKOFF_MS
                }
                parse(text, language)?.let { _events.tryEmit(it) }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                synchronized(lock) {
                    sockets.remove(language)
                }
                _connectedLanguages.value = _connectedLanguages.value - language
                scheduleReconnect(language)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                synchronized(lock) {
                    sockets.remove(language)
                }
                _connectedLanguages.value = _connectedLanguages.value - language
                if (code != NORMAL_CLOSURE) {
                    scheduleReconnect(language)
                }
            }
        })

        synchronized(lock) {
            sockets[language] = ws
        }
        _connectedLanguages.value = _connectedLanguages.value + language
    }

    fun disconnect(language: String) {
        synchronized(lock) {
            reconnectJobs.remove(language)?.cancel()
            backoffDelays.remove(language)
            sockets.remove(language)
        }?.close(NORMAL_CLOSURE, null)
        _connectedLanguages.value = _connectedLanguages.value - language
    }

    fun disconnectAll() {
        val languages: List<String>
        synchronized(lock) {
            languages = sockets.keys.toList()
        }
        languages.forEach { disconnect(it) }
    }

    private fun scheduleReconnect(language: String) {
        synchronized(lock) {
            reconnectJobs[language]?.cancel()
            val currentDelay = backoffDelays.getOrPut(language) { INITIAL_BACKOFF_MS }
            // Advance backoff for next attempt
            backoffDelays[language] = (currentDelay * 2).coerceAtMost(MAX_BACKOFF_MS)
            reconnectJobs[language] = scope.launch {
                delay(currentDelay)
                synchronized(lock) {
                    sockets.remove(language)
                }
                connect(language)
            }
        }
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
