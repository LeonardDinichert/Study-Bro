package com.studybro.app.account.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.studybro.app.core.di.FirebaseModule

@Composable
fun EditProfileScreen() {
    val name = remember { mutableStateOf(FirebaseModule.auth.currentUser?.displayName ?: "") }
    Column {
        OutlinedTextField(value = name.value, onValueChange = { name.value = it }, label = { Text("Name") })
        Spacer(Modifier.height(8.dp))
        Button(onClick = {
            FirebaseModule.auth.currentUser?.updateProfile(
                com.google.firebase.auth.UserProfileChangeRequest.Builder().setDisplayName(name.value).build()
            )
        }) { Text("Save") }
    }
}
