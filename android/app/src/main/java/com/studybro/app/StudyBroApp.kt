package com.studybro.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import com.stripe.android.PaymentConfiguration

class StudyBroApp : Application() {
    override fun onCreate() {
        super.onCreate()
        val publishableKey = "pk_test_51RtVPCAgKukMvTmDbG8vNZCcJN2gEt3WEyTGGXLZtCYMH0PFm9OrjfGaxQ5HZ8ln0c71iH4w4YcBiVA0LQ9ubFdG00uzQ2gIi2" // TODO replace with real key or load securely
        if (publishableKey.isNotEmpty()) {
            PaymentConfiguration.init(applicationContext, publishableKey)
        }
        if (!hasGoogleServices()) {
            Log.w("StudyBroApp", "google-services.json missing. Firebase may not be configured.")
        }
        createNotificationChannels()
    }

    private fun hasGoogleServices(): Boolean {
        return try {
            assets.open("google-services.json").close()
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val tasks = NotificationChannel("tasks", "Tasks", NotificationManager.IMPORTANCE_DEFAULT)
            val general = NotificationChannel("general", "General", NotificationManager.IMPORTANCE_DEFAULT)
            manager.createNotificationChannel(tasks)
            manager.createNotificationChannel(general)
        }
    }
}
