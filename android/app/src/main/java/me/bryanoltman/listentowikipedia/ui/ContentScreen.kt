package me.bryanoltman.listentowikipedia.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import me.bryanoltman.listentowikipedia.networking.WikipediaEvent
import me.bryanoltman.listentowikipedia.networking.WikipediaWebSocketService
import me.bryanoltman.listentowikipedia.ui.theme.AppBackground
import java.net.URLEncoder

private val DEFAULT_LANGUAGES = setOf("en")

@Composable
fun ContentScreen() {
    val uriHandler = LocalUriHandler.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()

    val webSocketService = remember { WikipediaWebSocketService() }
    val bubbleManager = remember { BubbleManager() }

    var tappedBubble by remember { mutableStateOf<Bubble?>(null) }
    var tapClearJob by remember { mutableStateOf<Job?>(null) }
    var newUser by remember { mutableStateOf<WikipediaEvent.NewUser?>(null) }
    var newUserClearJob by remember { mutableStateOf<Job?>(null) }

    val connectedLanguages by webSocketService.connectedLanguages.collectAsState()

    DisposableEffect(Unit) {
        view.keepScreenOn = true
        onDispose {
            view.keepScreenOn = false
            webSocketService.disconnectAll()
        }
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        for (lang in DEFAULT_LANGUAGES) {
            webSocketService.connect(lang)
        }
    }

    LifecycleEventEffect(Lifecycle.Event.ON_PAUSE) {
        webSocketService.disconnectAll()
    }

    LaunchedEffect(Unit) {
        webSocketService.events.collect { event ->
            when (event) {
                is WikipediaEvent.ArticleEdit -> {
                    bubbleManager.addBubble(event)
                }

                is WikipediaEvent.NewUser -> {
                    newUser = event
                    newUserClearJob?.cancel()
                    newUserClearJob = scope.launch {
                        delay(8_000)
                        newUser = null
                    }
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppBackground)
    ) {
        BubblesCanvas(
            manager = bubbleManager,
            onBubbleTap = { bubble ->
                tappedBubble = bubble
                tapClearJob?.cancel()
                tapClearJob = scope.launch {
                    delay(3_000)
                    tappedBubble = null
                }
            }
        )

        // Connecting indicator
        AnimatedVisibility(
            visible = connectedLanguages.isEmpty(),
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 50.dp),
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Text(
                text = "Connecting...",
                fontSize = 12.sp,
                color = Color.White.copy(alpha = 0.7f),
                modifier = Modifier
                    .background(
                        color = Color.Black.copy(alpha = 0.5f),
                        shape = RoundedCornerShape(50)
                    )
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            )
        }

        // New user banner
        AnimatedVisibility(
            visible = newUser != null,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 52.dp),
            enter = slideInVertically { -it } + fadeIn(),
            exit = slideOutVertically { -it } + fadeOut()
        ) {
            newUser?.let { user ->
                NewUserBanner(
                    username = user.username,
                    onTap = { uriHandler.openUri(userTalkPageUrl(user)) }
                )
            }
        }

        // Article toast
        AnimatedVisibility(
            visible = tappedBubble != null,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp),
            enter = slideInVertically { it } + fadeIn(),
            exit = slideOutVertically { it } + fadeOut()
        ) {
            tappedBubble?.let { bubble ->
                ArticleToast(
                    title = bubble.title,
                    articleUrl = bubble.articleUrl,
                    onTap = { bubble.articleUrl?.let { uriHandler.openUri(it) } }
                )
            }
        }
    }
}

private fun userTalkPageUrl(user: WikipediaEvent.NewUser): String {
    val encoded = URLEncoder.encode(user.username, "UTF-8")
    return "https://${user.language}.wikipedia.org/w/index.php?title=User_talk:$encoded&action=edit&section=new"
}
