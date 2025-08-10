package com.studybro.app.tasks.work

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class ReminderWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        val title = inputData.getString("title") ?: return Result.failure()
        val taskId = inputData.getString("taskId") ?: ""
        val notification = NotificationCompat.Builder(applicationContext, "tasks")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Task due")
            .setContentText(title)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(applicationContext).notify(taskId.hashCode(), notification)
        return Result.success()
    }
}
