package com.studybro.app.sessions.ui

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
import com.studybro.app.sessions.vm.StudySessionViewModel

@Composable
fun StudySessionScreen(navController: NavController, vm: StudySessionViewModel = viewModel()) {
    val remaining by vm.remaining.collectAsState()
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Time remaining: ${remaining/1000}s")
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { vm.start(25*60*1000L) }) { Text("Start") }
            Button(onClick = { vm.stop(); navController.popBackStack() }) { Text("Stop") }
        }
    }
}
