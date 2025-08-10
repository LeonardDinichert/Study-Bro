package com.studybro.app.core.util

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.remove
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

val Context.dataStore by preferencesDataStore(name = "settings")

object PreferencesKeys {
    val HAS_SHOWN_WELCOME = booleanPreferencesKey("hasShownWelcome")
}

suspend fun Context.setHasShownWelcome(value: Boolean) {
    dataStore.edit { it[PreferencesKeys.HAS_SHOWN_WELCOME] = value }
}

fun Context.hasShownWelcomeFlow(): Flow<Boolean> =
    dataStore.data.map { it[PreferencesKeys.HAS_SHOWN_WELCOME] ?: false }

private fun taskKey(taskId: String) = stringPreferencesKey("task_reminder_" + taskId)

suspend fun Context.setTaskReminderId(taskId: String, workId: String) {
    dataStore.edit { it[taskKey(taskId)] = workId }
}

suspend fun Context.getTaskReminderId(taskId: String): String? {
    return dataStore.data.first()[taskKey(taskId)]
}

suspend fun Context.clearTaskReminderId(taskId: String) {
    dataStore.edit { it.remove(taskKey(taskId)) }
}
