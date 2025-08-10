package com.studybro.app.notes.util

import com.google.firebase.Timestamp
import com.studybro.app.notes.model.Importance
import java.util.Calendar
import java.util.Date

object ReviewScheduler {
    private val high = listOf(1,3,7,14)
    private val medium = listOf(2,5,10)
    private val low = listOf(3,7,14)

    fun nextReview(importance: Importance, reviewCount: Int, now: Timestamp = Timestamp.now()): Timestamp {
        val days = when(importance) {
            Importance.HIGH -> high
            Importance.MEDIUM -> medium
            Importance.LOW -> low
        }
        val addDays = if (reviewCount < days.size) days[reviewCount] else days.last() * (reviewCount - days.size + 2)
        val cal = Calendar.getInstance().apply {
            time = now.toDate()
            add(Calendar.DAY_OF_YEAR, addDays)
        }
        return Timestamp(Date(cal.timeInMillis))
    }
}
