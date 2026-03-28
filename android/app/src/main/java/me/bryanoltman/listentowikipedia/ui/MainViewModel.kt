package me.bryanoltman.listentowikipedia.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.bryanoltman.listentowikipedia.audio.NotePlayer
import me.bryanoltman.listentowikipedia.data.AppSettings
import me.bryanoltman.listentowikipedia.data.SoundFontParser
import me.bryanoltman.listentowikipedia.model.EditSoundType
import me.bryanoltman.listentowikipedia.model.MusicalScale
import me.bryanoltman.listentowikipedia.model.SoundFontInstrument
import me.bryanoltman.listentowikipedia.model.WikipediaEvent
import me.bryanoltman.listentowikipedia.model.WikipediaNewUser
import me.bryanoltman.listentowikipedia.network.WikipediaWebSocketService

class MainViewModel(application: Application) : AndroidViewModel(application) {

    val settings = AppSettings(application)
    val webSocketService = WikipediaWebSocketService()
    private val notePlayer = NotePlayer()

    private val _bubbles = MutableStateFlow<List<Bubble>>(emptyList())
    val bubbles: StateFlow<List<Bubble>> = _bubbles.asStateFlow()

    private val _tappedBubble = MutableStateFlow<Bubble?>(null)
    val tappedBubble: StateFlow<Bubble?> = _tappedBubble.asStateFlow()

    private val _tappedBubbleId = MutableStateFlow<String?>(null)
    val tappedBubbleId: StateFlow<String?> = _tappedBubbleId.asStateFlow()

    private val _tapTimeNanos = MutableStateFlow(0L)
    val tapTimeNanos: StateFlow<Long> = _tapTimeNanos.asStateFlow()

    private val _newUser = MutableStateFlow<WikipediaNewUser?>(null)
    val newUser: StateFlow<WikipediaNewUser?> = _newUser.asStateFlow()

    private var toastDismissJob: Job? = null
    private var bannerDismissJob: Job? = null

    private val _instruments = MutableStateFlow<List<SoundFontInstrument>>(emptyList())
    val instruments: StateFlow<List<SoundFontInstrument>> = _instruments.asStateFlow()

    /** Canvas dimensions in px, updated by the composable. */
    var canvasWidth: Float = 400f
    var canvasHeight: Float = 800f

    /** Minimum bubble radius in px (set from 15.dp by MainScreen). */
    var minBubbleRadiusPx: Float = 15f

    init {
        notePlayer.start(settings.instrumentPrograms.value)

        // Parse SF2 instruments eagerly so the list is ready before settings opens
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val stream = application.assets.open("GeneralUser-GS.sf2")
                _instruments.value = SoundFontParser.instruments(stream)
            } catch (_: Exception) { }
        }

        // Sync WebSocket connections whenever selected languages change
        viewModelScope.launch {
            settings.selectedLanguageCodes.collect { codes ->
                syncConnections(codes)
            }
        }

        // React to instrument changes
        viewModelScope.launch {
            settings.instrumentPrograms.collect { programs ->
                for ((type, program) in programs) {
                    notePlayer.loadInstrument(program, type)
                }
            }
        }

        // Process incoming WebSocket events
        viewModelScope.launch {
            webSocketService.events.collect { event ->
                when (event) {
                    is WikipediaEvent.ArticleEdit -> {
                        val edit = event.edit
                        addBubble(edit)
                        if (!settings.isMuted.value) {
                            val note = MusicalScale.noteForEdit(
                                changeSize = edit.changeSize,
                                scale = settings.currentScale.value
                            )
                            if (note != null) {
                                val soundType = if (edit.changeSize >= 0)
                                    EditSoundType.ADDITION else EditSoundType.SUBTRACTION
                                notePlayer.play(note, type = soundType)
                            }
                        }
                    }
                    is WikipediaEvent.NewUser -> {
                        val user = event.user
                        _newUser.value = user
                        bannerDismissJob?.cancel()
                        bannerDismissJob = viewModelScope.launch {
                            delay(8000)
                            _newUser.value = null
                        }
                        if (!settings.isMuted.value) {
                            val scale = settings.currentScale.value
                            if (scale.isNotEmpty()) {
                                val randomNote = scale.random()
                                notePlayer.play(randomNote, type = EditSoundType.NEW_USER)
                            }
                        }
                    }
                }
            }
        }
    }

    private fun addBubble(edit: me.bryanoltman.listentowikipedia.model.WikipediaArticleEdit) {
        val now = System.nanoTime()
        val (fill, label, shadow) = bubbleColors(edit)
        val bubble = Bubble(
            creationTimeNanos = now,
            normalizedX = (0.05f + Math.random().toFloat() * 0.90f),
            normalizedY = (0.05f + Math.random().toFloat() * 0.90f),
            fillColor = fill,
            labelColor = label,
            labelShadowColor = shadow,
            size = BubblePhysics.bubbleSize(edit.changeSize, minOf(canvasWidth, canvasHeight), minBubbleRadiusPx),
            title = edit.pageTitle,
            articleUrl = articleUrl(edit.language, edit.pageTitle)
        )
        val cutoff = now - (BubblePhysics.LIFESPAN * 1_000_000_000).toLong()
        _bubbles.value = _bubbles.value.filter { it.creationTimeNanos > cutoff } + bubble
    }

    fun onBubbleTapped(bubble: Bubble) {
        _tappedBubble.value = bubble
        _tappedBubbleId.value = bubble.id
        _tapTimeNanos.value = System.nanoTime()
        toastDismissJob?.cancel()
        toastDismissJob = viewModelScope.launch {
            delay(3000)
            _tappedBubble.value = null
        }
    }

    fun onStart() {
        syncConnections(settings.selectedLanguageCodes.value)
    }

    fun onStop() {
        webSocketService.disconnectAll()
    }

    private fun syncConnections(selected: Set<String>) {
        val connected = webSocketService.connectedLanguages.value
        for (lang in connected) {
            if (lang !in selected) webSocketService.disconnect(lang)
        }
        for (lang in selected) {
            if (lang !in connected) webSocketService.connect(lang)
        }
    }

    override fun onCleared() {
        super.onCleared()
        webSocketService.disconnectAll()
        notePlayer.stop()
    }
}
