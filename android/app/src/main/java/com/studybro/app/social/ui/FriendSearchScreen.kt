package com.studybro.app.social.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.studybro.app.social.vm.SocialViewModel
import kotlinx.coroutines.launch

@Composable
fun FriendSearchScreen(navController: NavController, vm: SocialViewModel = SocialViewModel()) {
    val email = remember { mutableStateOf("") }
    val result = remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    Column(modifier = Modifier.fillMaxWidth()) {
        OutlinedTextField(value = email.value, onValueChange = { email.value = it }, label = { Text("Email") })
        Spacer(Modifier.height(8.dp))
        Button(onClick = {
            scope.launch {
                val user = vm.searchByEmail(email.value)
                result.value = user?.uid
            }
        }) { Text("Search") }
        result.value?.let { uid ->
            Spacer(Modifier.height(16.dp))
            Text("User: $uid")
            Button(onClick = { vm.sendRequest(uid); navController.popBackStack() }) { Text("Add friend") }
        }
    }
}
