package com.studybro.app.user.repo

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.storage.FirebaseStorage
import com.studybro.app.user.model.User
import kotlinx.coroutines.tasks.await

class UserRepository(
    private val firestore: FirebaseFirestore,
    private val storage: FirebaseStorage
) {
    suspend fun getCurrentUser(uid: String): User? {
        return firestore.collection("users").document(uid).get().await().toObject(User::class.java)
    }

    suspend fun updateUser(user: User) {
        firestore.collection("users").document(user.uid).set(user).await()
    }

    suspend fun uploadProfileImage(uid: String, bytes: ByteArray): String {
        val ref = storage.reference.child("profileImages/$uid.jpg")
        ref.putBytes(bytes).await()
        return ref.downloadUrl.await().toString()
    }
}
