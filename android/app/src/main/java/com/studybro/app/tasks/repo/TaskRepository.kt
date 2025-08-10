package com.studybro.app.tasks.repo

import android.content.Context
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.studybro.app.core.util.clearTaskReminderId
import com.studybro.app.core.util.getTaskReminderId
import com.studybro.app.core.util.setTaskReminderId
import com.studybro.app.tasks.model.TaskItem
import com.studybro.app.tasks.work.ReminderWorker
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.util.UUID
import java.util.concurrent.TimeUnit

class TaskRepository(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore,
    private val context: Context
) {
    private fun tasksCollection() =
        auth.currentUser?.uid?.let { uid ->
            firestore.collection("users").document(uid).collection("tasks")
        } ?: firestore.collection("users").document("__") // dummy to avoid null

    fun observeTasks(): Flow<List<TaskItem>> = callbackFlow {
        val registration = tasksCollection().orderBy("dueAt").addSnapshotListener { snap, _ ->
            val tasks = snap?.documents?.mapNotNull {
                it.toObject(TaskItem::class.java)?.copy(id = it.id)
            } ?: emptyList()
            trySend(tasks)
        }
        awaitClose { registration.remove() }
    }

    suspend fun addTask(title: String, dueAt: Timestamp) {
        val doc = tasksCollection().document()
        val task = TaskItem(id = doc.id, title = title, dueAt = dueAt, completed = false, createdAt = Timestamp.now())
        doc.set(task).await()
        scheduleReminder(task)
    }

    suspend fun toggleDone(task: TaskItem) {
        tasksCollection().document(task.id).update("completed", !task.completed).await()
        if (!task.completed) {
            cancelReminder(task.id)
        } else {
            task.dueAt?.let { scheduleReminder(task.copy(completed = true)) }
        }
    }

    suspend fun deleteTask(taskId: String) {
        cancelReminder(taskId)
        tasksCollection().document(taskId).delete().await()
    }

    private suspend fun scheduleReminder(task: TaskItem) {
        val due = task.dueAt?.toDate()?.time ?: return
        val delay = due - System.currentTimeMillis()
        if (delay <= 0) return
        val request = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(
                workDataOf(
                    "taskId" to task.id,
                    "title" to task.title
                )
            )
            .build()
        WorkManager.getInstance(context).enqueue(request)
        context.setTaskReminderId(task.id, request.id.toString())
    }

    private suspend fun cancelReminder(taskId: String) {
        context.getTaskReminderId(taskId)?.let {
            WorkManager.getInstance(context).cancelWorkById(UUID.fromString(it))
            context.clearTaskReminderId(taskId)
        }
    }
}
