package com.studybro.app.stats.vm

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.studybro.app.core.di.FirebaseModule
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class StatsViewModel(app: Application) : AndroidViewModel(app) {
    private val auth = FirebaseModule.auth
    private val firestore = FirebaseModule.firestore
    private val _streak = MutableStateFlow(0)
    val streak: StateFlow<Int> = _streak
    private val _longest = MutableStateFlow(0)
    val longest: StateFlow<Int> = _longest
    private val _totalStudy = MutableStateFlow(0L)
    val totalStudy: StateFlow<Long> = _totalStudy
    private val _tasksCompleted = MutableStateFlow(0)
    val tasksCompleted: StateFlow<Int> = _tasksCompleted
    private val _notesReviewed = MutableStateFlow(0)
    val notesReviewed: StateFlow<Int> = _notesReviewed

    init { viewModelScope.launch { load() } }

    private suspend fun load() {
        val uid = auth.currentUser?.uid ?: return
        val user = firestore.collection("users").document(uid).get().await()
        _streak.value = user.getLong("streak")?.toInt() ?: 0
        _longest.value = user.getLong("longestStreak")?.toInt() ?: 0
        val sessions = firestore.collection("users").document(uid).collection("sessions").get().await()
        _totalStudy.value = sessions.documents.sumOf { it.getLong("durationMs") ?: 0L }
        val tasks = firestore.collection("users").document(uid).collection("tasks").whereEqualTo("completed", true).get().await()
        _tasksCompleted.value = tasks.size()
        val notes = firestore.collection("users").document(uid).collection("learningNotes").get().await()
        _notesReviewed.value = notes.documents.sumOf { it.getLong("reviewCount")?.toInt() ?: 0 }
    }
}
