package me.bryanoltman.listentowikipedia.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import me.bryanoltman.listentowikipedia.model.MusicalKey
import me.bryanoltman.listentowikipedia.model.MusicalMode
import me.bryanoltman.listentowikipedia.model.MusicalScale

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

class AppSettings(context: Context) {
    private val dataStore = context.dataStore
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private object Keys {
        val SELECTED_LANGUAGES = stringSetPreferencesKey("selectedLanguages")
        val MUSICAL_KEY = stringPreferencesKey("musicalKey")
        val MUSICAL_MODE = stringPreferencesKey("musicalMode")
        val IS_MUTED = booleanPreferencesKey("isMuted")
        val INSTRUMENT_PROGRAM = intPreferencesKey("selectedInstrumentProgram")
        val ROOT_OCTAVE = intPreferencesKey("rootOctave")
        val OCTAVE_RANGE = intPreferencesKey("octaveRange")
    }

    val selectedLanguageCodes: StateFlow<Set<String>> = dataStore.data
        .map { it[Keys.SELECTED_LANGUAGES] ?: setOf("en") }
        .stateIn(scope, SharingStarted.Eagerly, setOf("en"))

    val musicalKey: StateFlow<MusicalKey> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.MUSICAL_KEY] ?: MusicalKey.B.name
            MusicalKey.entries.find { it.name == name } ?: MusicalKey.B
        }
        .stateIn(scope, SharingStarted.Eagerly, MusicalKey.B)

    val musicalMode: StateFlow<MusicalMode> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.MUSICAL_MODE] ?: MusicalMode.DORIAN.name
            MusicalMode.entries.find { it.name == name } ?: MusicalMode.DORIAN
        }
        .stateIn(scope, SharingStarted.Eagerly, MusicalMode.DORIAN)

    val isMuted: StateFlow<Boolean> = dataStore.data
        .map { it[Keys.IS_MUTED] ?: false }
        .stateIn(scope, SharingStarted.Eagerly, false)

    val selectedInstrumentProgram: StateFlow<Int> = dataStore.data
        .map { it[Keys.INSTRUMENT_PROGRAM] ?: 24 }
        .stateIn(scope, SharingStarted.Eagerly, 24)

    val rootOctave: StateFlow<Int> = dataStore.data
        .map { it[Keys.ROOT_OCTAVE] ?: 2 }
        .stateIn(scope, SharingStarted.Eagerly, 2)

    val octaveRange: StateFlow<Int> = dataStore.data
        .map { it[Keys.OCTAVE_RANGE] ?: 2 }
        .stateIn(scope, SharingStarted.Eagerly, 2)

    val currentScale: StateFlow<List<Int>> = combine(
        musicalKey, musicalMode, rootOctave, octaveRange
    ) { key, mode, octave, range ->
        MusicalScale.notes(
            root = key.midiNote(octave),
            mode = mode,
            octaves = range
        )
    }.stateIn(
        scope,
        SharingStarted.Eagerly,
        MusicalScale.notes(root = MusicalKey.B.midiNote(2), mode = MusicalMode.DORIAN, octaves = 2)
    )

    fun setSelectedLanguageCodes(codes: Set<String>) {
        scope.launch { dataStore.edit { it[Keys.SELECTED_LANGUAGES] = codes } }
    }

    fun setMusicalKey(key: MusicalKey) {
        scope.launch { dataStore.edit { it[Keys.MUSICAL_KEY] = key.name } }
    }

    fun setMusicalMode(mode: MusicalMode) {
        scope.launch { dataStore.edit { it[Keys.MUSICAL_MODE] = mode.name } }
    }

    fun setMuted(muted: Boolean) {
        scope.launch { dataStore.edit { it[Keys.IS_MUTED] = muted } }
    }

    fun setSelectedInstrumentProgram(program: Int) {
        scope.launch { dataStore.edit { it[Keys.INSTRUMENT_PROGRAM] = program } }
    }

    fun setRootOctave(octave: Int) {
        scope.launch { dataStore.edit { it[Keys.ROOT_OCTAVE] = octave } }
    }

    fun setOctaveRange(range: Int) {
        scope.launch { dataStore.edit { it[Keys.OCTAVE_RANGE] = range } }
    }
}
