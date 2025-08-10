package com.studybro.app.tasks.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import androidx.compose.ui.platform.LocalContext
import com.google.firebase.Timestamp
import com.studybro.app.tasks.model.TaskItem
import com.studybro.app.tasks.vm.TasksViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun TasksScreen(navController: NavController, viewModel: TasksViewModel = viewModel()) {
    val tasks by viewModel.tasks.collectAsState()
    Scaffold(floatingActionButton = {
        FloatingActionButton(onClick = { navController.navigate("tasks/add") }) {
            Icon(Icons.Filled.Add, contentDescription = "Add")
        }
    }) { padding ->
        if (tasks.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("No tasks")
            }
        } else {
            LazyColumn(Modifier.padding(padding)) {
                items(tasks) { task -> TaskRow(task, onToggle = { viewModel.toggleDone(task) }, onDelete = { viewModel.deleteTask(task.id) }) }
            }
        }
    }
}

@Composable
private fun TaskRow(task: TaskItem, onToggle: () -> Unit, onDelete: () -> Unit) {
    val sdf = remember { SimpleDateFormat("MMM d, HH:mm", Locale.getDefault()) }
    val due = task.dueAt?.toDate()?.let { sdf.format(it) } ?: ""
    val overdue = task.dueAt?.toDate()?.before(Date()) == true && !task.completed
    Row(
        Modifier.fillMaxWidth().padding(16.dp).background(Color.Transparent),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f).clickable { onToggle() }) {
            Text(task.title, fontWeight = if (task.completed) FontWeight.Light else FontWeight.Bold)
            if (due.isNotEmpty()) Text(due, color = if (overdue) Color.Red else Color.Unspecified)
        }
        TextButton(onClick = onDelete) { Text("Delete") }
    }
}

@Composable
fun AddTaskScreen(navController: NavController, viewModel: TasksViewModel = viewModel()) {
    var title = remember { androidx.compose.runtime.mutableStateOf("") }
    var date = remember { androidx.compose.runtime.mutableStateOf<Timestamp?>(null) }
    var showDatePicker = remember { androidx.compose.runtime.mutableStateOf(false) }
    if (showDatePicker.value) {
        DatePickerDialog(onDismissRequest = { showDatePicker.value = false }, onDateChange = {
            date.value = Timestamp(Date(it))
            showDatePicker.value = false
        })
    }
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(value = title.value, onValueChange = { title.value = it }, label = { Text("Title") })
        TextButton(onClick = { showDatePicker.value = true }) { Text(date.value?.toDate().toString().takeIf { it != "null" } ?: "Select date") }
        Button(onClick = {
            val due = date.value ?: Timestamp.now()
            viewModel.addTask(title.value, due)
            navController.popBackStack()
        }, enabled = title.value.isNotBlank()) { Text("Save") }
    }
}

// Simple DatePicker using Android DatePickerDialog
@Composable
private fun DatePickerDialog(onDismissRequest: () -> Unit, onDateChange: (Long) -> Unit) {
    val context = LocalContext.current
    val now = remember { java.util.Calendar.getInstance() }
    androidx.compose.runtime.LaunchedEffect(Unit) {
        android.app.DatePickerDialog(
            context,
            { _, y, m, d ->
                val cal = java.util.Calendar.getInstance()
                cal.set(y, m, d)
                onDateChange(cal.timeInMillis)
            },
            now.get(java.util.Calendar.YEAR),
            now.get(java.util.Calendar.MONTH),
            now.get(java.util.Calendar.DAY_OF_MONTH)
        ).apply { setOnDismissListener { onDismissRequest() } }.show()
    }
}
