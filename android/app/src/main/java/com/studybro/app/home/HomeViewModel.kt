package com.studybro.app.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.tasks.model.TaskItem
import com.studybro.app.user.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class HomeViewModel(app: Application) : AndroidViewModel(app) {
    private val auth = FirebaseModule.auth
    private val firestore = FirebaseModule.firestore
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user
    private val _nextTask = MutableStateFlow<TaskItem?>(null)
    val nextTask: StateFlow<TaskItem?> = _nextTask

    init { viewModelScope.launch { load() } }

    private suspend fun load() {
        val uid = auth.currentUser?.uid ?: return
        val userSnap = firestore.collection("users").document(uid).get().await()
        _user.value = userSnap.toObject(User::class.java)
        val taskSnap = firestore.collection("users").document(uid).collection("tasks")
            .whereEqualTo("completed", false).orderBy("dueAt").limit(1).get().await()
        val doc = taskSnap.documents.firstOrNull()
        _nextTask.value = doc?.toObject(TaskItem::class.java)?.copy(id = doc.id)
    }
}
