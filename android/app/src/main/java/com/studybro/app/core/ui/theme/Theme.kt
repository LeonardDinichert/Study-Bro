package com.studybro.app.core.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val ColorScheme = lightColorScheme(
    primary = PrimaryBlue
)

@Composable
fun StudyBroTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = ColorScheme,
        typography = Typography,
        content = content
    )
}
