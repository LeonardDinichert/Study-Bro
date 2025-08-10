package com.studybro.app.user.util

import java.time.LocalDate

object StreakCalculator {
    fun updateStreak(lastStudy: LocalDate?, current: LocalDate, streak: Int, longest: Int): Pair<Int, Int> {
        val yesterday = current.minusDays(1)
        val newStreak = when (lastStudy) {
            current -> streak
            yesterday -> streak + 1
            else -> 1
        }
        val newLongest = kotlin.math.max(longest, newStreak)
        return newStreak to newLongest
    }
}
