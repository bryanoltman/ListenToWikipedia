package me.bryanoltman.listentowikipedia.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import me.bryanoltman.listentowikipedia.audio.EditSoundType
import me.bryanoltman.listentowikipedia.audio.GeneralMidiCatalog
import me.bryanoltman.listentowikipedia.model.AppSettings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InstrumentPickerScreen(
    editSoundType: EditSoundType,
    settings: AppSettings,
    onBack: () -> Unit,
) {
    val instrumentPrograms by settings.instrumentPrograms.collectAsState()
    val selectedProgram = instrumentPrograms[editSoundType] ?: editSoundType.defaultProgram

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(editSoundType.displayName) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            items(GeneralMidiCatalog.instruments, key = { it.program }) { instrument ->
                val isSelected = instrument.program == selectedProgram
                ListItem(
                    headlineContent = { Text(instrument.name) },
                    trailingContent = {
                        if (isSelected) {
                            Icon(
                                Icons.Default.Check,
                                contentDescription = "Selected",
                                tint = MaterialTheme.colorScheme.primary,
                            )
                        }
                    },
                    modifier = Modifier.clickable {
                        val current = settings.instrumentPrograms.value.toMutableMap()
                        current[editSoundType] = instrument.program
                        settings.setInstrumentPrograms(current)
                    },
                )
            }
        }
    }
}
