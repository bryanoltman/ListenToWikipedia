package me.bryanoltman.listentowikipedia.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import me.bryanoltman.listentowikipedia.BuildConfig
import me.bryanoltman.listentowikipedia.ui.theme.DotGreen
import me.bryanoltman.listentowikipedia.ui.theme.DotPurple

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(onBack: () -> Unit) {
    val uriHandler = LocalUriHandler.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("About") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // How It Works
            Text("How It Works", style = MaterialTheme.typography.titleMedium)

            Text(
                "This app shows edits to Wikipedia as they happen in real time. " +
                        "Each bubble represents a single edit to an article.",
                style = MaterialTheme.typography.bodyMedium,
            )

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                LegendRow(color = Color.White, label = "Registered user edit")
                LegendRow(color = DotGreen, label = "Anonymous edit")
                LegendRow(color = DotPurple, label = "Bot edit")
            }

            Text(
                "When a new user registers on Wikipedia, a blue banner appears at the top of the screen. " +
                        "Tap the banner to visit their talk page and say hello.",
                style = MaterialTheme.typography.bodyMedium,
            )

            Text(
                "Larger bubbles represent larger edits. Light bubbles are additions; dark bubbles are removals.",
                style = MaterialTheme.typography.bodyMedium,
            )

            Text(
                "Tap a bubble to see the article title, then tap the title to open the article.",
                style = MaterialTheme.typography.bodyMedium,
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

            // Credits
            Text("Credits", style = MaterialTheme.typography.titleMedium)

            Row {
                Text(
                    "Developed by ",
                    style = MaterialTheme.typography.bodyMedium,
                )

                LinkText(
                    "Bryan Oltman",
                    url = "https://bryanoltman.com",
                    onClick = { uriHandler.openUri(it) },
                )
            }

            Row {
                Text(
                    "Inspired by ",
                    style = MaterialTheme.typography.bodyMedium,
                )

                LinkText(
                    text = "Hatnote's Listen to Wikipedia",
                    url = "http://listen.hatnote.com",
                    onClick = { uriHandler.openUri(it) },
                )
            }

            LinkText(
                text = "\"GeneralUser GS\" SoundFont by S. Christian Collins, GeneralUser GS License v2.0",
                url = "https://www.schristiancollins.com/generaluser",
                onClick = { uriHandler.openUri(it) },
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

            // Version
            Text(
                "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun LegendRow(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .clip(CircleShape)
                .background(color)
                .border(
                    0.5.dp,
                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
                    CircleShape
                ),
        )
        Text(label, style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun LinkText(text: String, url: String, onClick: (String) -> Unit) {
    val annotatedString = buildAnnotatedString {
        pushStringAnnotation(tag = "URL", annotation = url)
        withStyle(
            style = SpanStyle(
                color = MaterialTheme.colorScheme.primary,
                textDecoration = TextDecoration.Underline,
            ),
        ) {
            append(text)
        }
        pop()
    }

    @Suppress("DEPRECATION")
    ClickableText(
        text = annotatedString,
        style = MaterialTheme.typography.bodyMedium,
        onClick = { offset ->
            annotatedString.getStringAnnotations(tag = "URL", start = offset, end = offset)
                .firstOrNull()?.let { onClick(it.item) }
        },
    )
}
