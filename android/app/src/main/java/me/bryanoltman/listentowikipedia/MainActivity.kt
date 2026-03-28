package me.bryanoltman.listentowikipedia

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import me.bryanoltman.listentowikipedia.ui.MainScreen
import me.bryanoltman.listentowikipedia.ui.MainViewModel
import me.bryanoltman.listentowikipedia.ui.theme.ListenToWikipediaTheme

class MainActivity : ComponentActivity() {
    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ListenToWikipediaTheme {
                MainScreen(viewModel = viewModel)
            }
        }
    }
}
