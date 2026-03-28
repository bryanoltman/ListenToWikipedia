package me.bryanoltman.listentowikipedia

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import android.view.WindowManager
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import me.bryanoltman.listentowikipedia.ui.MainScreen
import me.bryanoltman.listentowikipedia.ui.MainViewModel
import me.bryanoltman.listentowikipedia.ui.theme.ListenToWikipediaTheme

class MainActivity : ComponentActivity() {
    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        setContent {
            ListenToWikipediaTheme {
                MainScreen(viewModel = viewModel)
            }
        }
    }
}
