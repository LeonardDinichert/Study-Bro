package com.studybro.app.notes.work

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.firebase.Timestamp
import com.studybro.app.core.di.FirebaseModule
import kotlinx.coroutines.tasks.await

class DueNotesWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        val uid = FirebaseModule.auth.currentUser?.uid ?: return Result.success()
        val now = Timestamp.now()
        val snap = FirebaseModule.firestore.collection("users").document(uid)
            .collection("learningNotes").whereLessThanOrEqualTo("nextReview", now).get().await()
        val count = snap.size()
        if (count > 0) {
            val notification = NotificationCompat.Builder(applicationContext, "general")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("Study Bro")
                .setContentText("You have $count notes to review today")
                .build()
            NotificationManagerCompat.from(applicationContext).notify(2001, notification)
        }
        return Result.success()
    }
}
