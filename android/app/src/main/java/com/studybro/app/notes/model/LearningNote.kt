package com.studybro.app.notes.model

import com.google.firebase.Timestamp

enum class Importance { LOW, MEDIUM, HIGH }

data class LearningNote(
    val id: String = "",
    val category: String = "",
    val text: String = "",
    val importance: Importance = Importance.LOW,
    val reviewCount: Int = 0,
    val nextReview: Timestamp? = null,
    val createdAt: Timestamp? = null
)
