package me.bryanoltman.listentowikipedia.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import java.net.URLEncoder
import me.bryanoltman.listentowikipedia.ui.theme.DarkBackground

@Composable
fun MainScreen(viewModel: MainViewModel) {
    val bubbles by viewModel.bubbles.collectAsState()
    val tappedBubble by viewModel.tappedBubble.collectAsState()
    val tappedBubbleId by viewModel.tappedBubbleId.collectAsState()
    val tapTimeNanos by viewModel.tapTimeNanos.collectAsState()
    val newUser by viewModel.newUser.collectAsState()
    val isMuted by viewModel.settings.isMuted.collectAsState()
    val context = LocalContext.current
    val density = LocalDensity.current

    var showSettings by remember { mutableStateOf(false) }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> viewModel.onStart()
                Lifecycle.Event.ON_STOP -> viewModel.onStop()
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .onSizeChanged { size ->
                viewModel.canvasWidth = with(density) { size.width.toFloat() }
            }
    ) {
        // Dark background + bubble canvas
        Surface(
            color = DarkBackground,
            modifier = Modifier.fillMaxSize()
        ) {
            BubblesCanvas(
                bubbles = bubbles,
                tappedBubbleId = tappedBubbleId,
                tapTimeNanos = tapTimeNanos,
                onBubbleTap = { viewModel.onBubbleTapped(it) }
            )
        }

        // Top-right overlay buttons
        Column(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = Color.Black.copy(alpha = 0.5f),
                modifier = Modifier.size(48.dp)
            ) {
                IconButton(onClick = { showSettings = true }) {
                    Icon(
                        imageVector = Icons.Filled.Settings,
                        contentDescription = "Settings",
                        tint = Color.White
                    )
                }
            }

            Spacer(modifier = Modifier.padding(vertical = 4.dp))

            Surface(
                shape = CircleShape,
                color = Color.Black.copy(alpha = 0.5f),
                modifier = Modifier.size(48.dp)
            ) {
                IconButton(onClick = { viewModel.settings.setMuted(!isMuted) }) {
                    Icon(
                        imageVector = if (isMuted) Icons.AutoMirrored.Filled.VolumeOff else Icons.AutoMirrored.Filled.VolumeUp,
                        contentDescription = if (isMuted) "Unmute" else "Mute",
                        tint = if (isMuted) Color.Gray else Color.White
                    )
                }
            }
        }

        // Bottom toast
        ArticleToast(
            bubble = tappedBubble,
            onTap = {
                tappedBubble?.articleUrl?.let { url ->
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                }
            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .windowInsetsPadding(WindowInsets.navigationBars)
        )

        // New user banner
        NewUserBanner(
            user = newUser,
            onTap = {
                newUser?.let { u ->
                    val encoded = URLEncoder.encode(u.username, "UTF-8")
                    val url = "https://${u.language}.wikipedia.org/w/index.php?title=User_talk:$encoded&action=edit&section=new"
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                }
            },
            modifier = Modifier
                .align(Alignment.TopCenter)
                .windowInsetsPadding(WindowInsets.statusBars)
        )

    }

    // Settings as a full-screen dialog (no experimental APIs)
    if (showSettings) {
        Dialog(
            onDismissRequest = { showSettings = false },
            properties = DialogProperties(
                usePlatformDefaultWidth = false,
                decorFitsSystemWindows = false
            )
        ) {
            SettingsScreen(
                settings = viewModel.settings,
                instruments = viewModel.instruments.collectAsState().value,
                onDismiss = { showSettings = false }
            )
        }
    }
}
