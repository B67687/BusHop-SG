package com.bushop.sg.data.local

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext

data class BusStopEntry(
    val code: String,
    val name: String,
    val road: String = ""
) {
    val displayName: String get() = if (name.isNotBlank()) "$name, $road" else code
}

class BusStopIndex(private val context: Context) {

    @Volatile
    private var stops: Map<String, BusStopEntry> = emptyMap()

    private val _isReady = MutableStateFlow(false)
    val isReady: StateFlow<Boolean> = _isReady.asStateFlow()

    init { /* empty — parsing is done in load() */ }

    /** Load and parse the JSON on [Dispatchers.IO]. Safe to call multiple times. */
    suspend fun load() {
        withContext(Dispatchers.IO) {
            val json = try {
                context.assets.open("bus_stops.json")
                    .bufferedReader()
                    .use { it.readText() }
            } catch (e: Exception) {
                "{}"
            }
            val type = object : TypeToken<Map<String, List<Any>>>() {}.type
            val raw: Map<String, List<Any>> = try {
                Gson().fromJson(json, type) ?: emptyMap()
            } catch (e: Exception) {
                emptyMap()
            }
            val parsed = raw.mapNotNull { (code, data) ->
                if (data.size >= 3) {
                    val name = data[2].toString().trim()
                    val road = data.getOrNull(3)?.toString()?.trim() ?: ""
                    if (name.isNotBlank()) BusStopEntry(code, name, road) else null
                } else null
            }
            stops = parsed.associateBy { it.code }
        }
        _isReady.value = true
    }

    /** Returns empty results if index hasn't loaded yet. */
    fun search(query: String): List<BusStopEntry> {
        val q = query.trim().lowercase()
        if (q.length < 1 || stops.isEmpty()) return emptyList()

        // Fast path: pure digit queries — code prefix only
        if (q.all { it.isDigit() }) {
            return stops.values
                .filter { it.code.startsWith(q) }
                .take(20)
        }

        // Scored relevance search for name/road queries
        data class Scored(val entry: BusStopEntry, val score: Int)
        val queryWords = q.split(" ")
        val results = stops.values.mapNotNull { entry ->
            val nameLower = entry.name.lowercase()
            val roadLower = entry.road.lowercase()
            val score = when {
                // Name starts with full query — excellent
                nameLower.startsWith(q) -> 800
                // Any word in name starts with full query — very good
                nameLower.split(" ").any { it.startsWith(q) } -> 700
                // Any word in name starts with any query word (min 2 chars) — good
                queryWords.any { word -> word.length >= 2 && nameLower.split(" ").any { it.startsWith(word) } } -> 600
                // All query words appear in name (substring) — decent
                queryWords.all { it in nameLower } -> 500
                // Any query word appears in name — fair
                queryWords.any { it in nameLower } -> 300
                // Any query word appears in road — weak
                queryWords.any { it in roadLower } -> 200
                // Name contains query as substring — fallback
                q in nameLower -> 100
                else -> null
            }?.let { Scored(entry, it) }
            score
        }
        return results
            .sortedByDescending { it.score }
            .take(20)
            .map { it.entry }
    }

    /** Returns null if index hasn't loaded yet. */
    fun findByCode(code: String): BusStopEntry? = stops[code]
}
