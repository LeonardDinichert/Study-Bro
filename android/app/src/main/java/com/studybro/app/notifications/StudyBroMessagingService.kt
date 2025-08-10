package com.studybro.app.notifications

import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.studybro.app.R
import com.studybro.app.core.di.FirebaseModule

class StudyBroMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        val uid = FirebaseModule.auth.currentUser?.uid ?: return
        FirebaseModule.firestore.collection("users").document(uid)
            .update("fcmToken", token)
            .addOnFailureListener { Log.w("MessagingService", "Token update failed", it) }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val manager = getSystemService(NotificationManager::class.java)
        val notif = NotificationCompat.Builder(this, "general")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(message.notification?.title)
            .setContentText(message.notification?.body)
            .build()
        manager.notify(0, notif)
    }
}
