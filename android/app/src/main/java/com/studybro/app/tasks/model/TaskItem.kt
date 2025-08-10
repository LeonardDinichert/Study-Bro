package com.studybro.app.tasks.model

import com.google.firebase.Timestamp

data class TaskItem(
    val id: String = "",
    val title: String = "",
    val dueAt: Timestamp? = null,
    val completed: Boolean = false,
    val createdAt: Timestamp? = null
)
