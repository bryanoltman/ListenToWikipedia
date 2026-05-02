package me.bryanoltman.listentowikipedia

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import me.bryanoltman.listentowikipedia.ui.ContentScreen
import me.bryanoltman.listentowikipedia.ui.theme.ListenToWikipediaTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ListenToWikipediaTheme {
                ContentScreen()
            }
        }
    }
}
