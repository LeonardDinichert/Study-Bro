package com.studybro.app.tasks.vm

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.Timestamp
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.tasks.model.TaskItem
import com.studybro.app.tasks.repo.TaskRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class TasksViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = TaskRepository(FirebaseModule.auth, FirebaseModule.firestore, app)

    val tasks: StateFlow<List<TaskItem>> =
        repo.observeTasks().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun addTask(title: String, dueAt: Timestamp) = viewModelScope.launch { repo.addTask(title, dueAt) }
    fun toggleDone(task: TaskItem) = viewModelScope.launch { repo.toggleDone(task) }
    fun deleteTask(id: String) = viewModelScope.launch { repo.deleteTask(id) }
}
