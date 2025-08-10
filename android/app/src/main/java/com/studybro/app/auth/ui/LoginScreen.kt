package com.studybro.app.auth.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun LoginScreen(
    onEmailLogin: () -> Unit,
    onGoogleLogin: () -> Unit,
    onRegister: () -> Unit,
    onForgotPassword: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Login")
        Button(onClick = onEmailLogin) { Text("Sign in") }
        Button(onClick = onGoogleLogin) { Text("Google") }
        Button(onClick = onRegister) { Text("Register") }
        Button(onClick = onForgotPassword) { Text("Reset Password") }
    }
}
