package com.studybro.app.user

import com.studybro.app.user.util.StreakCalculator
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class StreakCalculatorTest {
    @Test
    fun testIncrement() {
        val yesterday = LocalDate.now().minusDays(1)
        val (streak, longest) = StreakCalculator.updateStreak(yesterday, LocalDate.now(), 3, 5)
        assertEquals(4, streak)
        assertEquals(5, longest)
    }

    @Test
    fun testReset() {
        val oldDate = LocalDate.now().minusDays(5)
        val (streak, _) = StreakCalculator.updateStreak(oldDate, LocalDate.now(), 10, 12)
        assertEquals(1, streak)
    }
}
