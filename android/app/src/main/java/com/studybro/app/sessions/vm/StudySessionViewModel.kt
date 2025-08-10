package com.studybro.app.sessions.vm

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.Timestamp
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.sessions.repo.StudySessionRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.Date

class StudySessionViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = StudySessionRepository(FirebaseModule.auth, FirebaseModule.firestore)
    private var job: Job? = null
    private var startTime: Long = 0
    private val _remaining = MutableStateFlow(0L)
    val remaining: StateFlow<Long> = _remaining

    fun start(durationMs: Long, subject: String? = null) {
        startTime = System.currentTimeMillis()
        _remaining.value = durationMs
        job?.cancel()
        job = viewModelScope.launch {
            while (_remaining.value > 0) {
                delay(1000)
                _remaining.value -= 1000
            }
            finish(subject)
        }
    }

    fun stop(subject: String? = null) {
        job?.cancel()
        finish(subject)
    }

    private fun finish(subject: String?) {
        val end = System.currentTimeMillis()
        val duration = end - startTime
        viewModelScope.launch {
            repo.saveSession(duration, Timestamp(Date(startTime)), Timestamp(Date(end)), subject)
        }
    }
}
