package com.studybro.app.sessions.repo

import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.studybro.app.sessions.model.StudySession
import com.studybro.app.user.util.StreakCalculator
import kotlinx.coroutines.tasks.await
import java.time.ZoneId
import java.util.Date

class StudySessionRepository(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) {
    private fun sessionsCollection(uid: String) =
        firestore.collection("users").document(uid).collection("sessions")

    suspend fun saveSession(durationMs: Long, start: Timestamp, end: Timestamp, subject: String?) {
        val uid = auth.currentUser?.uid ?: return
        val doc = sessionsCollection(uid).document()
        val session = StudySession(doc.id, start, end, durationMs, subject)
        doc.set(session).await()
        updateStreak(uid, end.toDate())
    }

    private suspend fun updateStreak(uid: String, endDate: Date) {
        val userRef = firestore.collection("users").document(uid)
        firestore.runTransaction { tx ->
            val snap = tx.get(userRef)
            val currentStreak = snap.getLong("streak")?.toInt() ?: 0
            val longest = snap.getLong("longestStreak")?.toInt() ?: 0
            val last = snap.getTimestamp("lastStudyDate")?.toDate()?.toInstant()?.atZone(ZoneId.systemDefault())?.toLocalDate()
            val today = endDate.toInstant().atZone(ZoneId.systemDefault()).toLocalDate()
            val (newStreak, newLongest) = StreakCalculator.updateStreak(last, today, currentStreak, longest)
            tx.update(userRef, mapOf(
                "streak" to newStreak,
                "longestStreak" to newLongest,
                "lastStudyDate" to Timestamp(endDate)
            ))
            null
        }.await()
    }
}
