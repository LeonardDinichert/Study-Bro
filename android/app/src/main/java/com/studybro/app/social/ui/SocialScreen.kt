package com.studybro.app.social.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.studybro.app.social.vm.SocialViewModel

@Composable
fun SocialScreen(navController: NavController, vm: SocialViewModel = SocialViewModel()) {
    val friends by vm.friends.collectAsState()
    val pending by vm.pending.collectAsState()
    Column(modifier = Modifier.fillMaxSize()) {
        Button(onClick = { navController.navigate("social/search") }) { Text("Add Friend") }
        Text("Requests")
        LazyColumn {
            items(pending) { user ->
                Column {
                    Text(user.uid)
                    Button(onClick = { vm.accept(user.uid) }) { Text("Accept") }
                    Button(onClick = { vm.decline(user.uid) }) { Text("Decline") }
                }
            }
        }
        Text("Friends")
        LazyColumn {
            items(friends) { user ->
                Text(user.uid)
            }
        }
    }
}
