package com.studybro.app.auth.ui

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable

@Composable
fun ResetPasswordDialog(onDismiss: () -> Unit, onConfirm: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Reset password") },
        text = { Text("Password reset link will be sent") },
        confirmButton = { TextButton(onClick = onConfirm) { Text("Send") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
