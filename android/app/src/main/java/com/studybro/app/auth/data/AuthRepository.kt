package com.studybro.app.auth.data

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.studybro.app.user.model.User
import kotlinx.coroutines.tasks.await

class AuthRepository(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) {
    suspend fun signUp(email: String, password: String) {
        val result = auth.createUserWithEmailAndPassword(email, password).await()
        val uid = result.user?.uid ?: return
        val user = User(uid = uid, email = email)
        firestore.collection("users").document(uid).set(user).await()
    }

    suspend fun signIn(email: String, password: String) {
        auth.signInWithEmailAndPassword(email, password).await()
    }

    fun signOut() = auth.signOut()

    suspend fun sendPasswordReset(email: String) {
        auth.sendPasswordResetEmail(email).await()
    }

    suspend fun signInWithGoogle(idToken: String) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        auth.signInWithCredential(credential).await()
    }
}
