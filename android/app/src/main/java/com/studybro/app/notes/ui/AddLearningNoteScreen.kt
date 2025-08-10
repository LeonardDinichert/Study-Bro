package com.studybro.app.notes.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.studybro.app.notes.model.Importance
import com.studybro.app.notes.vm.NotesViewModel

@Composable
fun AddLearningNoteScreen(navController: NavController, vm: NotesViewModel = viewModel()) {
    val category = remember { mutableStateOf("") }
    val text = remember { mutableStateOf("") }
    val importance = remember { mutableStateOf(Importance.MEDIUM) }
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(category.value, { category.value = it }, label = { Text("Category") })
        OutlinedTextField(text.value, { text.value = it }, label = { Text("Text") })
        RowImportance(importance.value) { importance.value = it }
        Button(onClick = {
            vm.addNote(category.value, text.value, importance.value)
            navController.popBackStack()
        }, enabled = text.value.isNotBlank()) { Text("Save") }
    }
}

@Composable
private fun RowImportance(selected: Importance, onSelect: (Importance) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Importance.values().forEach { imp ->
            TextButton(onClick = { onSelect(imp) }) {
                Text(imp.name)
            }
        }
    }
}
