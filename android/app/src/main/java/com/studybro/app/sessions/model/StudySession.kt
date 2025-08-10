package com.studybro.app.sessions.model

import com.google.firebase.Timestamp

data class StudySession(
    val id: String = "",
    val start: Timestamp? = null,
    val end: Timestamp? = null,
    val durationMs: Long = 0,
    val subject: String? = null
)
