package com.studybro.app.home

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController

@Composable
fun HomeScreen(navController: NavController, vm: HomeViewModel = viewModel()) {
    val user by vm.user.collectAsState()
    val nextTask by vm.nextTask.collectAsState()
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Hello ${user?.displayName ?: ""}")
        Text("Streak: ${user?.streak ?: 0}")
        nextTask?.let { Text("Next task: ${it.title}") }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { navController.navigate("sessions") }) { Text("Start Session") }
            Button(onClick = { navController.navigate("notes/add") }) { Text("Add Note") }
            Button(onClick = { navController.navigate("tasks/add") }) { Text("Add Task") }
            Button(onClick = { navController.navigate("trophies") }) { Text("Trophies") }
        }
    }
}
