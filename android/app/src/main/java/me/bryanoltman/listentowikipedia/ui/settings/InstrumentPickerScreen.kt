package me.bryanoltman.listentowikipedia.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import me.bryanoltman.listentowikipedia.audio.EditSoundType
import me.bryanoltman.listentowikipedia.audio.SoundFontParser
import me.bryanoltman.listentowikipedia.model.AppSettings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InstrumentPickerScreen(
    editSoundType: EditSoundType,
    settings: AppSettings,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val instrumentsByBank = remember { SoundFontParser.bundledInstrumentsByBank(context) }
    val instrumentPrograms by settings.instrumentPrograms.collectAsState()
    val selectedId = instrumentPrograms[editSoundType] ?: editSoundType.defaultInstrumentId
    var searchQuery by remember { mutableStateOf("") }
    val filteredInstrumentsByBank = remember(searchQuery, instrumentsByBank) {
        if (searchQuery.isBlank()) {
            instrumentsByBank
        } else {
            instrumentsByBank
                .map { (bank, instruments) ->
                    bank to instruments.filter { it.name.contains(searchQuery, ignoreCase = true) }
                }
                .filter { (_, instruments) -> instruments.isNotEmpty() }
        }
    }

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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                label = { Text("Search instruments") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear search")
                        }
                    }
                },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
            )
            LazyColumn(
                modifier = Modifier.weight(1f),
            ) {
                if (filteredInstrumentsByBank.isEmpty()) {
                    item {
                        Text(
                            text = "No instruments found",
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        )
                    }
                }
                filteredInstrumentsByBank.forEach { (bank, instruments) ->
                    item(key = "header-$bank") {
                        Text(
                            text = bankDisplayName(bank),
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 16.dp, top = 24.dp, bottom = 8.dp),
                        )
                    }
                    items(instruments, key = { "${it.bank}-${it.program}" }) { instrument ->
                        val isSelected = instrument.id == selectedId
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
                                current[editSoundType] = instrument.id
                                settings.setInstrumentPrograms(current)
                            },
                        )
                    }
                }
            }
        }
    }
}

private fun bankDisplayName(bank: Int): String = when (bank) {
    0 -> "General MIDI"
    128 -> "GM Percussion"
    else -> "Bank $bank"
}
