package com.bushop.sg.domain.model

import org.junit.Assert.assertEquals
import org.junit.Test

/** Regression tests for [BusInfo.toDisplayArrival]. */
class BusArrivalTest {

    // ── ETA text ──

    @Test
    fun `eta shows Arr when less than 1 minute`() {
        val info = BusInfo(
            time = "2024-01-01T00:00:30+08:00", durationMs = 30_000,
            lat = null, lng = null, load = "SEA", feature = null, type = "SD",
            visitNumber = 1, originCode = null, destinationCode = null
        )
        val display = info.toDisplayArrival()
        assertEquals("Arr.", display.eta)
    }

    @Test
    fun `eta shows minutes when 1 minute or more`() {
        val info = BusInfo(
            time = "", durationMs = 120_000,
            lat = null, lng = null, load = "SEA", feature = null, type = "SD",
            visitNumber = 1, originCode = null, destinationCode = null
        )
        val display = info.toDisplayArrival()
        assertEquals("2 min", display.eta)
    }

    @Test
    fun `eta shows minute singular`() {
        val info = BusInfo(
            time = "", durationMs = 60_000,
            lat = null, lng = null, load = "SEA", feature = null, type = "SD",
            visitNumber = 1, originCode = null, destinationCode = null
        )
        val display = info.toDisplayArrival()
        assertEquals("1 min", display.eta)
    }

    @Test
    fun `eta at exactly 0 ms shows Arr`() {
        val info = BusInfo(
            time = "", durationMs = 0,
            lat = null, lng = null, load = "SEA", feature = null, type = "SD",
            visitNumber = 1, originCode = null, destinationCode = null
        )
        val display = info.toDisplayArrival()
        assertEquals("Arr.", display.eta)
    }

    // ── Load mapping ──

    @Test
    fun `load SEA maps to Seats Available`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "SD", 0, null, null)
        assertEquals("Seats Available", info.toDisplayArrival().load)
    }

    @Test
    fun `load SDA maps to Standing Available`() {
        val info = BusInfo("", 0, null, null, "SDA", null, "SD", 0, null, null)
        assertEquals("Standing Available", info.toDisplayArrival().load)
    }

    @Test
    fun `load LSD maps to Limited Standing`() {
        val info = BusInfo("", 0, null, null, "LSD", null, "SD", 0, null, null)
        assertEquals("Limited Standing", info.toDisplayArrival().load)
    }

    @Test
    fun `unknown load passes through unchanged`() {
        val info = BusInfo("", 0, null, null, "UNKNOWN", null, "SD", 0, null, null)
        assertEquals("UNKNOWN", info.toDisplayArrival().load)
    }

    // ── Bus type mapping ──

    @Test
    fun `bus type SD maps to Single Decker`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "SD", 0, null, null)
        assertEquals("Single Decker", info.toDisplayArrival().busType)
    }

    @Test
    fun `bus type DD maps to Double Decker`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "DD", 0, null, null)
        assertEquals("Double Decker", info.toDisplayArrival().busType)
    }

    @Test
    fun `bus type BD maps to Bendy`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "BD", 0, null, null)
        assertEquals("Bendy", info.toDisplayArrival().busType)
    }

    @Test
    fun `unknown bus type passes through unchanged`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "FE", 0, null, null)
        assertEquals("FE", info.toDisplayArrival().busType)
    }

    // ── WAB / Wheelchair accessible ──

    @Test
    fun `feature WAB returns isWheelchairAccessible true`() {
        val info = BusInfo("", 0, null, null, "SEA", "WAB", "SD", 0, null, null)
        assertEquals(true, info.toDisplayArrival().isWheelchairAccessible)
    }

    @Test
    fun `feature null returns isWheelchairAccessible false`() {
        val info = BusInfo("", 0, null, null, "SEA", null, "SD", 0, null, null)
        assertEquals(false, info.toDisplayArrival().isWheelchairAccessible)
    }

    @Test
    fun `feature other returns isWheelchairAccessible false`() {
        val info = BusInfo("", 0, null, null, "SEA", "OTHER", "SD", 0, null, null)
        assertEquals(false, info.toDisplayArrival().isWheelchairAccessible)
    }
}
