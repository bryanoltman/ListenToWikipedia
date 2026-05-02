package me.bryanoltman.listentowikipedia.networking

import android.util.Log
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
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import kotlin.math.ln

class WikipediaWebSocketService {

    private val client = OkHttpClient()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val sockets = mutableMapOf<String, WebSocket>()
    private val reconnectJobs = mutableMapOf<String, Job>()
    private val reconnectDelays = mutableMapOf<String, Long>()

    private val _connectedLanguages = MutableStateFlow<Set<String>>(emptySet())
    val connectedLanguages: StateFlow<Set<String>> = _connectedLanguages.asStateFlow()

    private val _events = MutableSharedFlow<WikipediaEvent>(extraBufferCapacity = 64)
    val events: SharedFlow<WikipediaEvent> = _events.asSharedFlow()

    fun connect(language: String) {
        if (sockets.containsKey(language)) return
        // Cancel any pending reconnect for this language.
        reconnectJobs.remove(language)?.cancel()
        performConnect(language)
    }

    fun disconnect(language: String) {
        Log.i(TAG, "Disconnecting from $language")
        reconnectJobs.remove(language)?.cancel()
        reconnectDelays.remove(language)
        sockets.remove(language)?.close(NORMAL_CLOSURE, null)
        _connectedLanguages.value -= language
    }

    fun disconnectAll() {
        Log.i(TAG, "Disconnecting all (${_connectedLanguages.value.size} connections)")
        reconnectJobs.values.forEach { it.cancel() }
        reconnectJobs.clear()
        reconnectDelays.clear()
        // Copy keys to avoid concurrent modification.
        sockets.keys.toList().forEach { disconnect(it) }
    }

    private fun performConnect(language: String) {
        val url = "wss://wikimon.hatnote.com/v2/$language"
        val request = Request.Builder().url(url).build()

        val listener = object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.i(TAG, "Connected to $language")
                reconnectDelays[language] = INITIAL_DELAY_MS
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                // Reset backoff on successful receive, matching iOS behavior.
                reconnectDelays[language] = INITIAL_DELAY_MS

                val event = WikipediaEvent.fromJson(text, language) ?: return
                _events.tryEmit(event)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "Connection error for $language: ${t.message}")
                sockets.remove(language)
                _connectedLanguages.value -= language
                scheduleReconnect(language)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.i(TAG, "Connection closed for $language (code=$code)")
                sockets.remove(language)
                _connectedLanguages.value -= language
                // Do not reconnect on normal closure (code 1000).
                if (code != NORMAL_CLOSURE) {
                    scheduleReconnect(language)
                }
            }
        }

        val socket = client.newWebSocket(request, listener)
        sockets[language] = socket
        _connectedLanguages.value += language
    }

    private fun scheduleReconnect(language: String) {
        reconnectJobs.remove(language)?.cancel()
        val currentDelay = reconnectDelays[language] ?: INITIAL_DELAY_MS
        val attempt = (ln(currentDelay.toDouble() / INITIAL_DELAY_MS) / ln(2.0)).toInt() + 1

        reconnectJobs[language] = scope.launch {
            delay(currentDelay)
            Log.i(TAG, "Reconnecting to $language (attempt $attempt, delay ${currentDelay}ms)")
            reconnectDelays[language] = (currentDelay * 2).coerceAtMost(MAX_DELAY_MS)
            performConnect(language)
        }
    }

    companion object {
        private const val TAG = "WebSocket"
        private const val NORMAL_CLOSURE = 1000
        private const val INITIAL_DELAY_MS = 1000L
        private const val MAX_DELAY_MS = 30_000L
    }
}
