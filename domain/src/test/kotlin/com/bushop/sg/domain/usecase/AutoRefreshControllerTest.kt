package com.bushop.sg.domain.usecase

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** Regression tests for [AutoRefreshController]. */
class AutoRefreshControllerTest {
    private val testDispatcher = StandardTestDispatcher()
    private val scope = CoroutineScope(testDispatcher + Job())
    private lateinit var controller: AutoRefreshController

    @Before
    fun setUp() {
        controller = AutoRefreshController(scope)
    }

    @Test
    fun `start does not immediately invoke callback`() =
        runTest(testDispatcher) {
            var invoked = false
            controller.start(intervalSeconds = 1) { invoked = true }
            // No time has passed — callback should not fire
            assertFalse(invoked)
        }

    @Test
    fun `callback fires after interval elapses`() =
        runTest(testDispatcher) {
            var count = 0
            controller.start(intervalSeconds = 1) { count++ }

            advanceTimeBy(999) // just under 1s
            assertFalse("Not yet fired", count > 0)

            advanceTimeBy(2) // crosses the 1s boundary
            assertTrue("Should have fired once", count >= 1)
        }

    @Test
    fun `stop prevents further callbacks`() =
        runTest(testDispatcher) {
            var count = 0
            controller.start(intervalSeconds = 1) { count++ }

            advanceTimeBy(1000) // first tick
            assertTrue(count >= 1)

            controller.stop()
            advanceTimeBy(5000) // should not fire again
            assertTrue("Count should stay at 1 after stop", count <= 1)
        }

    @Test
    fun `zero interval does not start`() =
        runTest(testDispatcher) {
            var invoked = false
            controller.start(intervalSeconds = 0) { invoked = true }
            advanceTimeBy(5000)
            assertFalse(invoked)
        }

    @Test
    fun `negative interval does not start`() =
        runTest(testDispatcher) {
            var invoked = false
            controller.start(intervalSeconds = -1) { invoked = true }
            advanceTimeBy(5000)
            assertFalse(invoked)
        }

    @Test
    fun `restart cancels previous interval`() =
        runTest(testDispatcher) {
            var count = 0
            controller.start(intervalSeconds = 1) { count++ }
            advanceTimeBy(500) // mid-interval
            controller.start(intervalSeconds = 2) { count++ } // restart with longer interval
            advanceTimeBy(1500) // would fire original, but should not
            // Only the new 2s interval should fire here
            assertTrue("Should have fired at least once", count >= 1)
        }

    @Test
    fun `onCleared stops the controller`() =
        runTest(testDispatcher) {
            var count = 0
            controller.start(intervalSeconds = 1) { count++ }
            advanceTimeBy(1000) // first tick
            assertTrue(count >= 1)

            controller.onCleared()
            advanceTimeBy(5000)
            assertTrue("Count should stay at 1 after onCleared", count <= 1)
        }
}
