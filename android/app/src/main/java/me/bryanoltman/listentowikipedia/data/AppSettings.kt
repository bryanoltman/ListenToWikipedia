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
import me.bryanoltman.listentowikipedia.model.EditSoundType
import me.bryanoltman.listentowikipedia.model.HeptatonicMode
import me.bryanoltman.listentowikipedia.model.MusicalKey
import me.bryanoltman.listentowikipedia.model.MusicalScale
import me.bryanoltman.listentowikipedia.model.PentatonicMode
import me.bryanoltman.listentowikipedia.model.ScaleType

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

class AppSettings(context: Context) {
    private val dataStore = context.dataStore
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private object Keys {
        val SELECTED_LANGUAGES = stringSetPreferencesKey("selectedLanguages")
        val MUSICAL_KEY = stringPreferencesKey("musicalKey")
        val SCALE_TYPE = stringPreferencesKey("scaleType")
        val HEPTATONIC_MODE = stringPreferencesKey("heptatonicMode")
        val PENTATONIC_MODE = stringPreferencesKey("pentatonicMode")
        val IS_MUTED = booleanPreferencesKey("isMuted")
        val ROOT_OCTAVE = intPreferencesKey("rootOctave")
        val OCTAVE_RANGE = intPreferencesKey("octaveRange")

        // Per-type instrument programs stored as individual keys
        fun instrumentProgram(type: EditSoundType) =
            intPreferencesKey("instrumentProgram_${type.name}")
    }

    // --- Defaults ---

    companion object {
        val DEFAULT_KEY = MusicalKey.F_SHARP
        val DEFAULT_SCALE_TYPE = ScaleType.PENTATONIC
        val DEFAULT_HEPTATONIC_MODE = HeptatonicMode.DORIAN
        val DEFAULT_PENTATONIC_MODE = PentatonicMode.MAJOR_PENTATONIC
        const val DEFAULT_ROOT_OCTAVE = 1
        const val DEFAULT_OCTAVE_RANGE = 3

        val DEFAULT_INSTRUMENT_PROGRAMS: Map<EditSoundType, Int> =
            EditSoundType.entries.associateWith { it.defaultProgram }
    }

    // --- Observable state ---

    val selectedLanguageCodes: StateFlow<Set<String>> = dataStore.data
        .map { it[Keys.SELECTED_LANGUAGES] ?: setOf("en") }
        .stateIn(scope, SharingStarted.Eagerly, setOf("en"))

    val musicalKey: StateFlow<MusicalKey> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.MUSICAL_KEY] ?: DEFAULT_KEY.name
            MusicalKey.entries.find { it.name == name } ?: DEFAULT_KEY
        }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_KEY)

    val scaleType: StateFlow<ScaleType> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.SCALE_TYPE] ?: DEFAULT_SCALE_TYPE.name
            ScaleType.entries.find { it.name == name } ?: DEFAULT_SCALE_TYPE
        }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_SCALE_TYPE)

    val heptatonicMode: StateFlow<HeptatonicMode> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.HEPTATONIC_MODE] ?: DEFAULT_HEPTATONIC_MODE.name
            HeptatonicMode.entries.find { it.name == name } ?: DEFAULT_HEPTATONIC_MODE
        }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_HEPTATONIC_MODE)

    val pentatonicMode: StateFlow<PentatonicMode> = dataStore.data
        .map { prefs ->
            val name = prefs[Keys.PENTATONIC_MODE] ?: DEFAULT_PENTATONIC_MODE.name
            PentatonicMode.entries.find { it.name == name } ?: DEFAULT_PENTATONIC_MODE
        }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_PENTATONIC_MODE)

    val isMuted: StateFlow<Boolean> = dataStore.data
        .map { it[Keys.IS_MUTED] ?: false }
        .stateIn(scope, SharingStarted.Eagerly, false)

    val instrumentPrograms: StateFlow<Map<EditSoundType, Int>> = dataStore.data
        .map { prefs ->
            EditSoundType.entries.associateWith { type ->
                prefs[Keys.instrumentProgram(type)] ?: type.defaultProgram
            }
        }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_INSTRUMENT_PROGRAMS)

    val rootOctave: StateFlow<Int> = dataStore.data
        .map { (it[Keys.ROOT_OCTAVE] ?: DEFAULT_ROOT_OCTAVE).coerceIn(0, 8) }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_ROOT_OCTAVE)

    val octaveRange: StateFlow<Int> = dataStore.data
        .map { (it[Keys.OCTAVE_RANGE] ?: DEFAULT_OCTAVE_RANGE).coerceIn(1, 4) }
        .stateIn(scope, SharingStarted.Eagerly, DEFAULT_OCTAVE_RANGE)

    /// Derived scale: combines key + mode + octave settings into MIDI note list.
    val currentScale: StateFlow<List<Int>> = combine(
        combine(musicalKey, scaleType, heptatonicMode) { key, st, hMode -> Triple(key, st, hMode) },
        combine(pentatonicMode, rootOctave, octaveRange) { pMode, octave, range -> Triple(pMode, octave, range) }
    ) { (key, st, hMode), (pMode, octave, range) ->
        val intervals = when (st) {
            ScaleType.PENTATONIC -> pMode.intervals
            ScaleType.HEPTATONIC -> hMode.intervals
        }
        MusicalScale.notes(
            root = key.midiNote(octave),
            intervals = intervals,
            octaves = range
        )
    }.stateIn(
        scope,
        SharingStarted.Eagerly,
        MusicalScale.notes(
            root = DEFAULT_KEY.midiNote(DEFAULT_ROOT_OCTAVE),
            intervals = DEFAULT_PENTATONIC_MODE.intervals,
            octaves = DEFAULT_OCTAVE_RANGE
        )
    )

    // --- Mutators ---

    fun setSelectedLanguageCodes(codes: Set<String>) {
        scope.launch { dataStore.edit { it[Keys.SELECTED_LANGUAGES] = codes } }
    }

    fun setMusicalKey(key: MusicalKey) {
        scope.launch { dataStore.edit { it[Keys.MUSICAL_KEY] = key.name } }
    }

    fun setScaleType(type: ScaleType) {
        scope.launch { dataStore.edit { it[Keys.SCALE_TYPE] = type.name } }
    }

    fun setHeptatonicMode(mode: HeptatonicMode) {
        scope.launch { dataStore.edit { it[Keys.HEPTATONIC_MODE] = mode.name } }
    }

    fun setPentatonicMode(mode: PentatonicMode) {
        scope.launch { dataStore.edit { it[Keys.PENTATONIC_MODE] = mode.name } }
    }

    fun setMuted(muted: Boolean) {
        scope.launch { dataStore.edit { it[Keys.IS_MUTED] = muted } }
    }

    fun setInstrumentProgram(type: EditSoundType, program: Int) {
        scope.launch { dataStore.edit { it[Keys.instrumentProgram(type)] = program } }
    }

    fun setRootOctave(octave: Int) {
        scope.launch { dataStore.edit { it[Keys.ROOT_OCTAVE] = octave.coerceIn(0, 8) } }
    }

    fun setOctaveRange(range: Int) {
        scope.launch { dataStore.edit { it[Keys.OCTAVE_RANGE] = range.coerceIn(1, 4) } }
    }

    fun resetToDefaults() {
        scope.launch {
            dataStore.edit { prefs ->
                prefs.remove(Keys.SELECTED_LANGUAGES)
                prefs.remove(Keys.MUSICAL_KEY)
                prefs.remove(Keys.SCALE_TYPE)
                prefs.remove(Keys.HEPTATONIC_MODE)
                prefs.remove(Keys.PENTATONIC_MODE)
                prefs.remove(Keys.IS_MUTED)
                prefs.remove(Keys.ROOT_OCTAVE)
                prefs.remove(Keys.OCTAVE_RANGE)
                for (type in EditSoundType.entries) {
                    prefs.remove(Keys.instrumentProgram(type))
                }
            }
        }
    }
}
