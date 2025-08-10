package com.studybro.app.trophies.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.studybro.app.trophies.vm.TrophiesViewModel

@Composable
fun TrophiesScreen(vm: TrophiesViewModel = viewModel()) {
    val trophies by vm.trophies.collectAsState()
    LazyColumn(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items(trophies) { trophy ->
            Text(
                text = "${trophy.threshold} day streak",
                color = if (trophy.achieved) Color.Green else Color.Gray
            )
        }
    }
}
