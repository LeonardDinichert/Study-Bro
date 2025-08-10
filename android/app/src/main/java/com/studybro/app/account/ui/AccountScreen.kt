package com.studybro.app.account.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.user.model.User
import kotlinx.coroutines.tasks.await

@Composable
fun AccountScreen(navController: NavController) {
    val authUser = FirebaseModule.auth.currentUser
    val user = remember { mutableStateOf<User?>(null) }
    LaunchedEffect(authUser) {
        authUser?.uid?.let { uid ->
            val snap = FirebaseModule.firestore.collection("users").document(uid).get().await()
            user.value = snap.toObject(User::class.java)
        }
    }
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(authUser?.displayName ?: "")
        Text(authUser?.email ?: "")
        if (user.value?.premium == true) { Text("Premium") }
        Button(onClick = { navController.navigate("account/edit") }) { Text("Edit Profile") }
        Button(onClick = { navController.navigate("account/subscribe") }) { Text("Subscribe") }
        Button(onClick = { navController.navigate("account/settings") }) { Text("Settings") }
        Button(onClick = { navController.navigate("account/privacy") }) { Text("Privacy") }
        Button(onClick = { navController.navigate("account/legal") }) { Text("Legal") }
        Button(onClick = { FirebaseModule.auth.signOut() }) { Text("Logout") }
    }
}
