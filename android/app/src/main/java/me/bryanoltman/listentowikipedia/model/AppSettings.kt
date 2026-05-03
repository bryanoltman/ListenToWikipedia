package me.bryanoltman.listentowikipedia.model

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow

class AppSettings private constructor(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    val selectedLanguageCodes: MutableStateFlow<Set<String>> =
        MutableStateFlow(prefs.getStringSet(KEY_SELECTED_LANGUAGES, DEFAULT_LANGUAGES) ?: DEFAULT_LANGUAGES)


    // --- Setters ---

    fun setSelectedLanguageCodes(codes: Set<String>) {
        selectedLanguageCodes.value = codes
        prefs.edit { putStringSet(KEY_SELECTED_LANGUAGES, codes) }
    }


    // --- Reset ---

    fun resetToDefaults() {
        setSelectedLanguageCodes(DEFAULT_LANGUAGES)
    }

    companion object {
        private const val PREFS_NAME = "listen_to_wikipedia_settings"

        private const val KEY_SELECTED_LANGUAGES = "selectedLanguages"

        private val DEFAULT_LANGUAGES = setOf("en")

        @Volatile
        private var instance: AppSettings? = null

        fun getInstance(context: Context): AppSettings {
            return instance ?: synchronized(this) {
                instance ?: AppSettings(context.applicationContext).also { instance = it }
            }
        }
    }
}
