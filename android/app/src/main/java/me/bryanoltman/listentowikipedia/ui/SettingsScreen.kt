package me.bryanoltman.listentowikipedia.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import me.bryanoltman.listentowikipedia.data.AppSettings
import me.bryanoltman.listentowikipedia.model.MusicalKey
import me.bryanoltman.listentowikipedia.model.MusicalMode
import me.bryanoltman.listentowikipedia.model.SoundFontInstrument
import me.bryanoltman.listentowikipedia.model.WikipediaLanguage
import me.bryanoltman.listentowikipedia.ui.theme.BubbleGreen
import me.bryanoltman.listentowikipedia.ui.theme.BubblePurple
import me.bryanoltman.listentowikipedia.ui.theme.BubbleWhite
import me.bryanoltman.listentowikipedia.ui.theme.DarkBackground

@Composable
fun SettingsScreen(
    settings: AppSettings,
    instruments: List<SoundFontInstrument>,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val selectedLanguages by settings.selectedLanguageCodes.collectAsState()
    val musicalKey by settings.musicalKey.collectAsState()
    val musicalMode by settings.musicalMode.collectAsState()
    val isMuted by settings.isMuted.collectAsState()
    val instrumentProgram by settings.selectedInstrumentProgram.collectAsState()
    val rootOctave by settings.rootOctave.collectAsState()
    val octaveRange by settings.octaveRange.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        // Header row replacing TopAppBar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onDismiss) {
                Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
            }
            Text(
                "Settings",
                style = MaterialTheme.typography.titleLarge,
                color = Color.White,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            // ---- Music Settings ----
            item {
                Text(
                    "Music",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(top = 8.dp, bottom = 8.dp)
                )
            }

            // Mute toggle
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Mute", color = Color.White)
                    Switch(
                        checked = isMuted,
                        onCheckedChange = { settings.setMuted(it) }
                    )
                }
            }

            // Instrument picker
            if (instruments.isNotEmpty()) {
                item {
                    val selectedInstrument = instruments.find { it.program == instrumentProgram }
                    val instrumentIndex = instruments.indexOfFirst { it.program == instrumentProgram }
                    var showInstrumentDialog by remember { mutableStateOf(false) }
                    Box(modifier = Modifier.fillMaxWidth()) {
                        OutlinedTextField(
                            value = selectedInstrument?.name ?: "Program $instrumentProgram",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Instrument") },
                            trailingIcon = {
                                Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                            },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Box(
                            modifier = Modifier
                                .matchParentSize()
                                .clickable { showInstrumentDialog = true }
                        )
                    }
                    if (showInstrumentDialog) {
                        ListPickerDialog(
                            title = "Select Instrument",
                            options = instruments.map { it.name },
                            selectedIndex = instrumentIndex,
                            onSelect = { index ->
                                settings.setSelectedInstrumentProgram(instruments[index].program)
                                showInstrumentDialog = false
                            },
                            onDismiss = { showInstrumentDialog = false }
                        )
                    }
                }
            }

            // Key picker
            item {
                var showKeyDialog by remember { mutableStateOf(false) }
                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = musicalKey.displayName,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Key") },
                        trailingIcon = {
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                        },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .clickable { showKeyDialog = true }
                    )
                }
                if (showKeyDialog) {
                    ListPickerDialog(
                        title = "Select Key",
                        options = MusicalKey.entries.map { it.displayName },
                        selectedIndex = MusicalKey.entries.indexOf(musicalKey),
                        onSelect = { index ->
                            settings.setMusicalKey(MusicalKey.entries[index])
                            showKeyDialog = false
                        },
                        onDismiss = { showKeyDialog = false }
                    )
                }
            }

            // Mode picker
            item {
                var showModeDialog by remember { mutableStateOf(false) }
                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = musicalMode.displayName,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Mode") },
                        trailingIcon = {
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                        },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .clickable { showModeDialog = true }
                    )
                }
                if (showModeDialog) {
                    ListPickerDialog(
                        title = "Select Mode",
                        options = MusicalMode.entries.map { it.displayName },
                        selectedIndex = MusicalMode.entries.indexOf(musicalMode),
                        onSelect = { index ->
                            settings.setMusicalMode(MusicalMode.entries[index])
                            showModeDialog = false
                        },
                        onDismiss = { showModeDialog = false }
                    )
                }
            }

            // Root octave stepper
            item {
                StepperRow(
                    label = "Root octave",
                    value = rootOctave,
                    range = 0..8,
                    onValueChange = { settings.setRootOctave(it) }
                )
            }

            // Octave range stepper
            item {
                StepperRow(
                    label = "Octave range",
                    value = octaveRange,
                    range = 1..4,
                    onValueChange = { settings.setOctaveRange(it) }
                )
            }

            // ---- Languages ----
            item {
                HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
                Text(
                    "Languages",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            items(WikipediaLanguage.all) { language ->
                val isSelected = selectedLanguages.contains(language.code)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(language.name, color = Color.White)
                    Switch(
                        checked = isSelected,
                        onCheckedChange = { on ->
                            val current = selectedLanguages.toMutableSet()
                            if (on) {
                                current.add(language.code)
                            } else {
                                if (current.size > 1) {
                                    current.remove(language.code)
                                }
                            }
                            settings.setSelectedLanguageCodes(current)
                        }
                    )
                }
            }

            // ---- About ----
            item {
                HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
                Text(
                    "About",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            item {
                Text(
                    "How It Works",
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    "This app shows edits to Wikipedia as they happen in real time. " +
                        "Each bubble represents a single edit to an article.",
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 12.dp)
                )

                LegendRow(color = BubbleWhite, label = "Registered user edit")
                LegendRow(color = BubbleGreen, label = "Anonymous edit")
                LegendRow(color = BubblePurple, label = "Bot edit")

                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    "Larger bubbles represent larger edits. " +
                        "Light bubbles are additions; dark bubbles are removals.",
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    "Tap a bubble to see the article title, " +
                        "then tap the toast to open the article.",
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
            }

            // Credits
            item {
                Text(
                    "Credits",
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    "Developed by Bryan Oltman",
                    color = Color.White,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    "Inspired by Hatnote's Listen to Wikipedia",
                    color = Color.White,
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier
                        .clickable {
                            context.startActivity(
                                Intent(Intent.ACTION_VIEW, Uri.parse("http://listen.hatnote.com"))
                            )
                        }
                        .padding(bottom = 8.dp)
                )
                Text(
                    "\"GeneralUser GS\" SoundFont by S. Christian Collins, " +
                        "GeneralUser GS License v2.0",
                    color = Color.White,
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier
                        .clickable {
                            context.startActivity(
                                Intent(
                                    Intent.ACTION_VIEW,
                                    Uri.parse("https://www.schristiancollins.com/generaluser")
                                )
                            )
                        }
                        .padding(bottom = 32.dp)
                )
            }
        }
    }
}

/**
 * Dialog for picking from a list of options.
 * Uses LazyColumn for smooth scrolling and reliable tap handling.
 */
@Composable
private fun ListPickerDialog(
    title: String,
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    androidx.compose.ui.window.Dialog(
        onDismissRequest = onDismiss,
        properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 48.dp)
                .background(
                    color = Color(0xFF2C3238),
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                }
            }
            HorizontalDivider()
            LazyColumn(
                modifier = Modifier.weight(1f, fill = false)
            ) {
                items(options.size) { index ->
                    val isSelected = index == selectedIndex
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(index) }
                            .background(if (isSelected) Color.White.copy(alpha = 0.1f) else Color.Transparent)
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = options[index],
                            color = if (isSelected) Color.White else Color.White.copy(alpha = 0.7f),
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StepperRow(
    label: String,
    value: Int,
    range: IntRange,
    onValueChange: (Int) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text("$label: $value", color = Color.White)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
                onClick = { if (value > range.first) onValueChange(value - 1) },
                enabled = value > range.first,
                contentPadding = PaddingValues(horizontal = 12.dp)
            ) {
                Text("-")
            }
            OutlinedButton(
                onClick = { if (value < range.last) onValueChange(value + 1) },
                enabled = value < range.last,
                contentPadding = PaddingValues(horizontal = 12.dp)
            ) {
                Text("+")
            }
        }
    }
}

@Composable
private fun LegendRow(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.padding(vertical = 4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(label, color = Color.White, fontSize = 14.sp)
    }
}
