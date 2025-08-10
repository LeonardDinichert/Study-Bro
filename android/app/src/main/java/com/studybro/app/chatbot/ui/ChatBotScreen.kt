package com.studybro.app.chatbot.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.studybro.app.chatbot.vm.ChatBotViewModel

@Composable
fun ChatBotScreen(vm: ChatBotViewModel = ChatBotViewModel()) {
    val messages by vm.messages.collectAsState()
    val input = remember { mutableStateOf("") }
    Column(modifier = Modifier.fillMaxSize()) {
        LazyColumn(modifier = Modifier.weight(1f)) {
            items(messages) { msg ->
                Text("${msg.role}: ${msg.content}")
            }
        }
        OutlinedTextField(value = input.value, onValueChange = { input.value = it })
        Button(onClick = { vm.sendMessage(input.value); input.value = "" }) { Text("Send") }
    }
}
