package me.bryanoltman.listentowikipedia.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import me.bryanoltman.listentowikipedia.audio.EditSoundType
import me.bryanoltman.listentowikipedia.audio.HeptatonicMode
import me.bryanoltman.listentowikipedia.audio.MusicalKey
import me.bryanoltman.listentowikipedia.audio.PentatonicMode
import me.bryanoltman.listentowikipedia.audio.ScaleType
import me.bryanoltman.listentowikipedia.audio.SoundFontParser
import me.bryanoltman.listentowikipedia.model.AppSettings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AudioSettingsScreen(
    settings: AppSettings,
    onNavigateToInstrumentPicker: (EditSoundType) -> Unit,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val instruments = remember { SoundFontParser.bundledInstruments(context) }
    val instrumentPrograms by settings.instrumentPrograms.collectAsState()
    val musicalKey by settings.musicalKey.collectAsState()
    val scaleType by settings.scaleType.collectAsState()
    val pentatonicMode by settings.pentatonicMode.collectAsState()
    val heptatonicMode by settings.heptatonicMode.collectAsState()
    val rootOctave by settings.rootOctave.collectAsState()
    val octaveRange by settings.octaveRange.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Audio") },
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
                .verticalScroll(rememberScrollState()),
        ) {
            // Instruments section
            SectionHeader("Instruments")
            EditSoundType.entries.forEach { type ->
                val selectedId = instrumentPrograms[type] ?: type.defaultInstrumentId
                val instrumentName = instruments
                    .find { it.bank == selectedId.bank && it.program == selectedId.program }
                    ?.name ?: "Unknown"
                ListItem(
                    headlineContent = { Text(type.displayName) },
                    supportingContent = { Text(instrumentName, color = MaterialTheme.colorScheme.onSurfaceVariant) },
                    modifier = Modifier.fillMaxWidth().clickable { onNavigateToInstrumentPicker(type) },
                )
            }

            // Scale section
            SectionHeader("Scale")

            // Key picker
            DropdownPicker(
                label = "Key",
                selectedValue = musicalKey.displayName,
                options = MusicalKey.entries.map { it.displayName },
                onOptionSelected = { index ->
                    settings.setMusicalKey(MusicalKey.entries[index])
                },
            )

            // Scale type picker
            DropdownPicker(
                label = "Scale Type",
                selectedValue = scaleType.displayName,
                options = ScaleType.entries.map { it.displayName },
                onOptionSelected = { index ->
                    settings.setScaleType(ScaleType.entries[index])
                },
            )

            // Mode picker (conditional)
            if (scaleType == ScaleType.PENTATONIC) {
                DropdownPicker(
                    label = "Mode",
                    selectedValue = pentatonicMode.displayName,
                    options = PentatonicMode.entries.map { it.displayName },
                    onOptionSelected = { index ->
                        settings.setPentatonicMode(PentatonicMode.entries[index])
                    },
                )
            } else {
                DropdownPicker(
                    label = "Mode",
                    selectedValue = heptatonicMode.displayName,
                    options = HeptatonicMode.entries.map { it.displayName },
                    onOptionSelected = { index ->
                        settings.setHeptatonicMode(HeptatonicMode.entries[index])
                    },
                )
            }

            // Root octave stepper
            StepperRow(
                label = "Root Octave",
                value = rootOctave,
                range = 0..8,
                onValueChange = { settings.setRootOctave(it) },
            )

            // Octave range stepper
            StepperRow(
                label = "Octave Range",
                value = octaveRange,
                range = 1..4,
                onValueChange = { settings.setOctaveRange(it) },
            )
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = 16.dp, top = 24.dp, bottom = 8.dp),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DropdownPicker(
    label: String,
    selectedValue: String,
    options: List<String>,
    onOptionSelected: (Int) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
    ) {
        TextField(
            value = selectedValue,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            colors = ExposedDropdownMenuDefaults.textFieldColors(),
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable).fillMaxWidth(),
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
        ) {
            options.forEachIndexed { index, option ->
                DropdownMenuItem(
                    text = { Text(option) },
                    onClick = {
                        onOptionSelected(index)
                        expanded = false
                    },
                )
            }
        }
    }
}

@Composable
private fun StepperRow(
    label: String,
    value: Int,
    range: IntRange,
    onValueChange: (Int) -> Unit,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Text("$label: $value", style = MaterialTheme.typography.bodyLarge)
        Spacer(modifier = Modifier.weight(1f))
        IconButton(
            onClick = { if (value > range.first) onValueChange(value - 1) },
            enabled = value > range.first,
        ) {
            Text("\u2212", style = MaterialTheme.typography.titleLarge)
        }
        Spacer(modifier = Modifier.width(8.dp))
        IconButton(
            onClick = { if (value < range.last) onValueChange(value + 1) },
            enabled = value < range.last,
        ) {
            Text("+", style = MaterialTheme.typography.titleLarge)
        }
    }
}
