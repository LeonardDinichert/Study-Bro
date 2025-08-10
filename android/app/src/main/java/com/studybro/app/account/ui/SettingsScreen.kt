package com.studybro.app.account.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier

@Composable
fun SettingsScreen() {
    val notifications = remember { mutableStateOf(true) }
    Column(modifier = Modifier.fillMaxWidth()) {
        Text("Notifications")
        Switch(checked = notifications.value, onCheckedChange = { notifications.value = it })
        // TODO store in DataStore
    }
}
