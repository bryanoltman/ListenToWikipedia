package me.bryanoltman.listentowikipedia.model

import android.content.Context
import android.content.SharedPreferences
import me.bryanoltman.listentowikipedia.audio.EditSoundType
import me.bryanoltman.listentowikipedia.audio.HeptatonicMode
import me.bryanoltman.listentowikipedia.audio.MusicalKey
import me.bryanoltman.listentowikipedia.audio.MusicalScale
import me.bryanoltman.listentowikipedia.audio.PentatonicMode
import me.bryanoltman.listentowikipedia.audio.ScaleType
import kotlinx.coroutines.flow.MutableStateFlow
import org.json.JSONObject

class AppSettings private constructor(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    val selectedLanguageCodes: MutableStateFlow<Set<String>> =
        MutableStateFlow(prefs.getStringSet(KEY_SELECTED_LANGUAGES, DEFAULT_LANGUAGES) ?: DEFAULT_LANGUAGES)

    val scaleType: MutableStateFlow<ScaleType> =
        MutableStateFlow(
            prefs.getString(KEY_SCALE_CARDINALITY, null)
                ?.let { name -> ScaleType.entries.firstOrNull { it.name == name } }
                ?: DEFAULT_SCALE_TYPE
        )

    val musicalKey: MutableStateFlow<MusicalKey> =
        MutableStateFlow(
            prefs.getString(KEY_MUSICAL_KEY, null)
                ?.let { name -> MusicalKey.entries.firstOrNull { it.name == name } }
                ?: DEFAULT_MUSICAL_KEY
        )

    val heptatonicMode: MutableStateFlow<HeptatonicMode> =
        MutableStateFlow(
            prefs.getString(KEY_MUSICAL_MODE, null)
                ?.let { name -> HeptatonicMode.entries.firstOrNull { it.name == name } }
                ?: DEFAULT_HEPTATONIC_MODE
        )

    val pentatonicMode: MutableStateFlow<PentatonicMode> =
        MutableStateFlow(
            prefs.getString(KEY_PENTATONIC_MODE, null)
                ?.let { name -> PentatonicMode.entries.firstOrNull { it.name == name } }
                ?: DEFAULT_PENTATONIC_MODE
        )

    val isMuted: MutableStateFlow<Boolean> =
        MutableStateFlow(prefs.getBoolean(KEY_IS_MUTED, DEFAULT_IS_MUTED))

    val instrumentPrograms: MutableStateFlow<Map<EditSoundType, Int>> =
        MutableStateFlow(loadInstrumentPrograms())

    val rootOctave: MutableStateFlow<Int> =
        MutableStateFlow(prefs.getInt(KEY_ROOT_OCTAVE, DEFAULT_ROOT_OCTAVE))

    val octaveRange: MutableStateFlow<Int> =
        MutableStateFlow(prefs.getInt(KEY_OCTAVE_RANGE, DEFAULT_OCTAVE_RANGE))

    // --- Setters ---

    fun setSelectedLanguageCodes(codes: Set<String>) {
        selectedLanguageCodes.value = codes
        prefs.edit().putStringSet(KEY_SELECTED_LANGUAGES, codes).apply()
    }

    fun setScaleType(value: ScaleType) {
        scaleType.value = value
        prefs.edit().putString(KEY_SCALE_CARDINALITY, value.name).apply()
    }

    fun setMusicalKey(value: MusicalKey) {
        musicalKey.value = value
        prefs.edit().putString(KEY_MUSICAL_KEY, value.name).apply()
    }

    fun setHeptatonicMode(value: HeptatonicMode) {
        heptatonicMode.value = value
        prefs.edit().putString(KEY_MUSICAL_MODE, value.name).apply()
    }

    fun setPentatonicMode(value: PentatonicMode) {
        pentatonicMode.value = value
        prefs.edit().putString(KEY_PENTATONIC_MODE, value.name).apply()
    }

    fun setIsMuted(value: Boolean) {
        isMuted.value = value
        prefs.edit().putBoolean(KEY_IS_MUTED, value).apply()
    }

    fun setInstrumentPrograms(value: Map<EditSoundType, Int>) {
        instrumentPrograms.value = value
        prefs.edit().putString(KEY_INSTRUMENT_PROGRAMS, serializeInstrumentPrograms(value)).apply()
    }

    fun setRootOctave(value: Int) {
        rootOctave.value = value.coerceIn(0, 8)
        prefs.edit().putInt(KEY_ROOT_OCTAVE, rootOctave.value).apply()
    }

    fun setOctaveRange(value: Int) {
        octaveRange.value = value.coerceIn(1, 4)
        prefs.edit().putInt(KEY_OCTAVE_RANGE, octaveRange.value).apply()
    }

    // --- Computed ---

    fun currentScale(): List<Int> {
        val root = musicalKey.value.midiNote(rootOctave.value)
        val intervals = when (scaleType.value) {
            ScaleType.PENTATONIC -> pentatonicMode.value.intervals
            ScaleType.HEPTATONIC -> heptatonicMode.value.intervals
        }
        return MusicalScale.notes(root, intervals, octaveRange.value)
    }

    // --- Reset ---

    fun resetToDefaults() {
        setSelectedLanguageCodes(DEFAULT_LANGUAGES)
        setScaleType(DEFAULT_SCALE_TYPE)
        setMusicalKey(DEFAULT_MUSICAL_KEY)
        setHeptatonicMode(DEFAULT_HEPTATONIC_MODE)
        setPentatonicMode(DEFAULT_PENTATONIC_MODE)
        setIsMuted(DEFAULT_IS_MUTED)
        setInstrumentPrograms(DEFAULT_INSTRUMENT_PROGRAMS)
        setRootOctave(DEFAULT_ROOT_OCTAVE)
        setOctaveRange(DEFAULT_OCTAVE_RANGE)
    }

    // --- Serialization helpers ---

    private fun loadInstrumentPrograms(): Map<EditSoundType, Int> {
        val json = prefs.getString(KEY_INSTRUMENT_PROGRAMS, null) ?: return DEFAULT_INSTRUMENT_PROGRAMS
        return try {
            val obj = JSONObject(json)
            val result = mutableMapOf<EditSoundType, Int>()
            for (type in EditSoundType.entries) {
                result[type] = if (obj.has(type.name)) obj.getInt(type.name) else type.defaultProgram
            }
            result
        } catch (_: Exception) {
            DEFAULT_INSTRUMENT_PROGRAMS
        }
    }

    private fun serializeInstrumentPrograms(programs: Map<EditSoundType, Int>): String {
        val obj = JSONObject()
        for ((type, program) in programs) {
            obj.put(type.name, program)
        }
        return obj.toString()
    }

    companion object {
        private const val PREFS_NAME = "listen_to_wikipedia_settings"

        private const val KEY_SELECTED_LANGUAGES = "selectedLanguages"
        private const val KEY_SCALE_CARDINALITY = "scaleCardinality"
        private const val KEY_MUSICAL_KEY = "musicalKey"
        private const val KEY_MUSICAL_MODE = "musicalMode"
        private const val KEY_PENTATONIC_MODE = "pentatonicMode"
        private const val KEY_IS_MUTED = "isMuted"
        private const val KEY_INSTRUMENT_PROGRAMS = "instrumentPrograms"
        private const val KEY_ROOT_OCTAVE = "rootOctave"
        private const val KEY_OCTAVE_RANGE = "octaveRange"

        private val DEFAULT_LANGUAGES = setOf("en")
        private val DEFAULT_SCALE_TYPE = ScaleType.PENTATONIC
        private val DEFAULT_MUSICAL_KEY = MusicalKey.F_SHARP
        private val DEFAULT_HEPTATONIC_MODE = HeptatonicMode.DORIAN
        private val DEFAULT_PENTATONIC_MODE = PentatonicMode.MAJOR_PENTATONIC
        private const val DEFAULT_IS_MUTED = false
        private val DEFAULT_INSTRUMENT_PROGRAMS = mapOf(
            EditSoundType.ADDITION to 8,
            EditSoundType.SUBTRACTION to 7,
            EditSoundType.NEW_USER to 89
        )
        private const val DEFAULT_ROOT_OCTAVE = 1
        private const val DEFAULT_OCTAVE_RANGE = 3

        @Volatile
        private var instance: AppSettings? = null

        fun getInstance(context: Context): AppSettings {
            return instance ?: synchronized(this) {
                instance ?: AppSettings(context.applicationContext).also { instance = it }
            }
        }
    }
}
