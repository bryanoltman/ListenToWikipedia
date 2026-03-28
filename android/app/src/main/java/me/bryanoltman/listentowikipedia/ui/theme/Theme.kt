package me.bryanoltman.listentowikipedia.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val AppColorScheme = darkColorScheme(
    primary = Color.White,
    onPrimary = DarkBackground,
    background = DarkBackground,
    onBackground = Color.White,
    surface = DarkBackground,
    onSurface = Color.White,
    surfaceVariant = Color(0xFF2C3238),
    onSurfaceVariant = Color(0xFFCAC4D0),
)

@Composable
fun ListenToWikipediaTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = AppColorScheme,
        typography = Typography,
        content = content
    )
}
