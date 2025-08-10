package com.studybro.app.notes

import com.google.firebase.Timestamp
import com.studybro.app.notes.model.Importance
import com.studybro.app.notes.util.ReviewScheduler
import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Date

class ReviewSchedulerTest {
    @Test
    fun testHighImportanceFirstReview() {
        val now = Timestamp(Date(0))
        val next = ReviewScheduler.nextReview(Importance.HIGH, 0, now)
        assertEquals(86400000L, next.toDate().time) // +1 day
    }
}
