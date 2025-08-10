package com.studybro.app.stats.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.studybro.app.stats.vm.StatsViewModel

@Composable
fun StatsScreen(vm: StatsViewModel = viewModel()) {
    val streak by vm.streak.collectAsState()
    val longest by vm.longest.collectAsState()
    val total by vm.totalStudy.collectAsState()
    val tasks by vm.tasksCompleted.collectAsState()
    val notes by vm.notesReviewed.collectAsState()
    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("Streak: $streak")
        Text("Longest streak: $longest")
        Text("Total study time: ${total/60000} min")
        Text("Tasks completed: $tasks")
        Text("Notes reviewed: $notes")
    }
}
