package com.studybro.app.notes.vm

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.notes.model.Importance
import com.studybro.app.notes.model.LearningNote
import com.studybro.app.notes.repo.NotesRepository
import kotlinx.coroutines.flow.*
import java.util.Date
import kotlinx.coroutines.launch

class NotesViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = NotesRepository(FirebaseModule.auth, FirebaseModule.firestore, app)
    val notes: StateFlow<List<LearningNote>> =
        repo.observeNotes().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val dueNotes: StateFlow<List<LearningNote>> =
        notes.map { list -> list.filter { it.nextReview?.toDate()?.before(Date()) == true } }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun addNote(category: String, text: String, importance: Importance) =
        viewModelScope.launch { repo.addNote(category, text, importance) }

    fun markReviewed(note: LearningNote) = viewModelScope.launch { repo.markReviewed(note) }
}
