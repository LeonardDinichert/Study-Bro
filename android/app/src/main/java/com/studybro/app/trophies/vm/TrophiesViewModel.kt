package com.studybro.app.trophies.vm

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.studybro.app.core.di.FirebaseModule
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

data class Trophy(val threshold: Int, val achieved: Boolean)

class TrophiesViewModel(app: Application) : AndroidViewModel(app) {
    private val _trophies = MutableStateFlow<List<Trophy>>(emptyList())
    val trophies: StateFlow<List<Trophy>> = _trophies

    init { viewModelScope.launch { load() } }

    private suspend fun load() {
        val uid = FirebaseModule.auth.currentUser?.uid ?: return
        val user = FirebaseModule.firestore.collection("users").document(uid).get().await()
        val streak = user.getLong("streak")?.toInt() ?: 0
        val thresholds = listOf(10, 15, 30)
        _trophies.value = thresholds.map { Trophy(it, streak >= it) }
    }
}
