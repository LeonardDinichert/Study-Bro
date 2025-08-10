package com.studybro.app.notes.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.studybro.app.notes.vm.NotesViewModel

@Composable
fun ReviewNotesScreen(vm: NotesViewModel = viewModel()) {
    val notes by vm.dueNotes.collectAsState()
    LazyColumn(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items(notes) { note ->
            Column(Modifier.fillMaxWidth()) {
                Text(note.text)
                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                    Text(note.category)
                    Button(onClick = { vm.markReviewed(note) }) { Text("Mark reviewed") }
                }
            }
        }
    }
}
