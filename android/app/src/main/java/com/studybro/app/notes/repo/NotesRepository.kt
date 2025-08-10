package com.studybro.app.notes.repo

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.studybro.app.notes.model.Importance
import com.studybro.app.notes.model.LearningNote
import com.studybro.app.notes.util.ReviewScheduler
import com.studybro.app.notes.work.DueNotesWorker
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.time.Duration
import java.time.LocalDateTime
import java.util.concurrent.TimeUnit

class NotesRepository(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore,
    private val context: Context
) {
    private fun notesCollection() = auth.currentUser?.uid?.let { uid ->
        firestore.collection("users").document(uid).collection("learningNotes")
    } ?: firestore.collection("users").document("__")

    fun observeNotes(): Flow<List<LearningNote>> = callbackFlow {
        val reg = notesCollection().addSnapshotListener { snap, _ ->
            val notes = snap?.documents?.mapNotNull { it.toObject(LearningNote::class.java)?.copy(id = it.id) } ?: emptyList()
            trySend(notes)
        }
        awaitClose { reg.remove() }
    }

    suspend fun addNote(category: String, text: String, importance: Importance) {
        val doc = notesCollection().document()
        val note = LearningNote(
            id = doc.id,
            category = category,
            text = text,
            importance = importance,
            reviewCount = 0,
            nextReview = ReviewScheduler.nextReview(importance, 0),
            createdAt = Timestamp.now()
        )
        doc.set(note).await()
        scheduleDailyCheck()
    }

    suspend fun markReviewed(note: LearningNote) {
        val next = ReviewScheduler.nextReview(note.importance, note.reviewCount + 1)
        notesCollection().document(note.id)
            .update(mapOf("reviewCount" to note.reviewCount + 1, "nextReview" to next))
            .await()
    }

    suspend fun fetchDueNotes(now: Timestamp): List<LearningNote> {
        val snap = notesCollection().whereLessThanOrEqualTo("nextReview", now).get().await()
        return snap.documents.mapNotNull { it.toObject(LearningNote::class.java)?.copy(id = it.id) }
    }

    private fun scheduleDailyCheck() {
        val wm = WorkManager.getInstance(context)
        val delay = computeDelayToNine()
        val req = PeriodicWorkRequestBuilder<DueNotesWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .build()
        wm.enqueueUniquePeriodicWork("daily_notes", ExistingPeriodicWorkPolicy.UPDATE, req)
    }

    private fun computeDelayToNine(): Long {
        val now = LocalDateTime.now()
        var next = now.withHour(9).withMinute(0).withSecond(0).withNano(0)
        if (now >= next) next = next.plusDays(1)
        return Duration.between(now, next).toMillis()
    }
}
