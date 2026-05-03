package me.bryanoltman.listentowikipedia.ui.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import me.bryanoltman.listentowikipedia.model.AppSettings

enum class SettingsPage { MAIN, LANGUAGES }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(settings: AppSettings, onDismiss: () -> Unit) {
    var currentPage by remember { mutableStateOf(SettingsPage.MAIN) }

    AnimatedContent(targetState = currentPage, label = "settings_nav") { page ->
        when (page) {
            SettingsPage.MAIN -> SettingsMainPage(
                settings = settings,
                onNavigateToLanguages = { currentPage = SettingsPage.LANGUAGES },
                onDismiss = onDismiss,
            )

            SettingsPage.LANGUAGES -> LanguagesScreen(
                settings = settings,
                onBack = { currentPage = SettingsPage.MAIN },
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsMainPage(
    settings: AppSettings,
    onNavigateToLanguages: () -> Unit,
    onDismiss: () -> Unit,
) {
    var showResetConfirmation by remember { mutableStateOf(false) }

    if (showResetConfirmation) {
        AlertDialog(
            onDismissRequest = { showResetConfirmation = false },
            title = { Text("Reset to Defaults") },
            text = { Text("Reset all settings to their defaults?") },
            confirmButton = {
                TextButton(onClick = {
                    settings.resetToDefaults()
                    showResetConfirmation = false
                }) {
                    Text("Reset", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetConfirmation = false }) {
                    Text("Cancel")
                }
            },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                actions = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Done")
                    }
                },
            )
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            ListItem(
                headlineContent = { Text("Languages") },
                modifier = Modifier.fillMaxWidth().clickable(onClick = onNavigateToLanguages),
            )
            ListItem(
                headlineContent = {
                    Text(
                        "Reset to Defaults",
                        color = MaterialTheme.colorScheme.error,
                    )
                },
                modifier = Modifier.fillMaxWidth().clickable { showResetConfirmation = true },
            )
        }
    }
}
