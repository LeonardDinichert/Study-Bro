package com.studybro.app.user.model

import com.google.firebase.Timestamp

data class User(
    val uid: String = "",
    val email: String? = null,
    val displayName: String? = null,
    val photoUrl: String? = null,
    val friends: List<String> = emptyList(),
    val pendingFriends: List<String> = emptyList(),
    val premium: Boolean = false,
    val streak: Int = 0,
    val longestStreak: Int = 0,
    val lastStudyDate: Timestamp? = null,
    val preferences: Map<String, Any>? = null,
    val fcmToken: String? = null
)
