package com.studybro.app.social.repo

import com.google.firebase.firestore.FieldValue
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.user.model.User
import kotlinx.coroutines.tasks.await

class SocialRepository {
    private val users = FirebaseModule.firestore.collection("users")

    suspend fun searchUserByEmail(email: String): User? {
        val snap = users.whereEqualTo("email", email).get().await()
        val doc = snap.documents.firstOrNull() ?: return null
        return doc.toObject(User::class.java)?.copy(uid = doc.id)
    }

    suspend fun sendFriendRequest(targetUid: String) {
        val uid = FirebaseModule.auth.currentUser?.uid ?: return
        FirebaseModule.firestore.runTransaction { tx ->
            val targetRef = users.document(targetUid)
            tx.update(targetRef, "pendingFriends", FieldValue.arrayUnion(uid))
        }.await()
    }

    suspend fun acceptFriendRequest(fromUid: String) {
        val uid = FirebaseModule.auth.currentUser?.uid ?: return
        FirebaseModule.firestore.runTransaction { tx ->
            val meRef = users.document(uid)
            val fromRef = users.document(fromUid)
            tx.update(meRef, "pendingFriends", FieldValue.arrayRemove(fromUid))
            tx.update(meRef, "friends", FieldValue.arrayUnion(fromUid))
            tx.update(fromRef, "friends", FieldValue.arrayUnion(uid))
        }.await()
    }

    suspend fun declineFriendRequest(fromUid: String) {
        val uid = FirebaseModule.auth.currentUser?.uid ?: return
        FirebaseModule.firestore.runTransaction { tx ->
            val meRef = users.document(uid)
            tx.update(meRef, "pendingFriends", FieldValue.arrayRemove(fromUid))
        }.await()
    }

    fun listenUser(uid: String, listener: (User?) -> Unit) =
        users.document(uid).addSnapshotListener { snapshot, _ ->
            listener(snapshot?.toObject(User::class.java)?.copy(uid = uid))
        }
}
