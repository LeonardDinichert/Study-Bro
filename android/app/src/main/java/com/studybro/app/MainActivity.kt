package com.studybro.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.studybro.app.account.ui.AccountScreen
import com.studybro.app.account.ui.EditProfileScreen
import com.studybro.app.account.ui.LegalScreen
import com.studybro.app.account.ui.PrivacyScreen
import com.studybro.app.account.ui.SettingsScreen
import com.studybro.app.account.ui.SubscribeScreen
import com.studybro.app.auth.ui.LoginScreen
import com.studybro.app.auth.ui.RegisterScreen
import com.studybro.app.core.di.FirebaseModule
import com.studybro.app.core.ui.theme.StudyBroTheme
import com.studybro.app.core.util.hasShownWelcomeFlow
import com.studybro.app.core.util.setHasShownWelcome
import com.studybro.app.home.HomeScreen
import com.studybro.app.onboarding.OnboardingScreen
import com.studybro.app.social.ui.FriendSearchScreen
import com.studybro.app.social.ui.SocialScreen
import com.studybro.app.stats.ui.StatsScreen
import com.studybro.app.tasks.ui.AddTaskScreen
import com.studybro.app.tasks.ui.TasksScreen
import com.studybro.app.trophies.ui.TrophiesScreen
import com.studybro.app.sessions.ui.StudySessionScreen
import com.studybro.app.chatbot.ui.ChatBotScreen
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0)
        }
        setContent {
            StudyBroTheme {
                val navController = rememberNavController()
                val context = this@MainActivity
                val hasShownWelcome by context.hasShownWelcomeFlow().collectAsState(initial = false)
                val startDest = remember(hasShownWelcome) {
                    when {
                        !hasShownWelcome -> "onboarding"
                        FirebaseModule.auth.currentUser == null -> "auth/login"
                        else -> "home"
                    }
                }
                val scope = rememberCoroutineScope()
                Scaffold(bottomBar = {
                    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
                    val tabs = listOf("home","tasks","social","stats","account")
                    if (currentRoute in tabs) {
                        NavigationBar {
                            tabs.forEach { route ->
                                val icon = when(route) {
                                    "home" -> Icons.Filled.Home
                                    "tasks" -> Icons.Filled.List
                                    "social" -> Icons.Filled.People
                                    "stats" -> Icons.Filled.BarChart
                                    "account" -> Icons.Filled.Person
                                    else -> Icons.Filled.Home
                                }
                                NavigationBarItem(
                                    selected = currentRoute == route,
                                    onClick = { navController.navigate(route) },
                                    icon = { Icon(icon, contentDescription = route) },
                                    label = { Text(route.replaceFirstChar{it.uppercase()}) }
                                )
                            }
                        }
                    }
                }) { padding ->
                    NavHost(navController, startDestination = startDest, modifier = Modifier.padding(padding)) {
                        composable("onboarding") {
                            OnboardingScreen {
                                scope.launch {
                                    context.setHasShownWelcome(true)
                                    if (FirebaseModule.auth.currentUser == null) {
                                        navController.navigate("auth/login") { popUpTo(0) }
                                    } else {
                                        navController.navigate("home") { popUpTo(0) }
                                    }
                                }
                            }
                        }
                        composable("auth/login") {
                            LoginScreen(
                                onEmailLogin = { /* TODO */ },
                                onGoogleLogin = { /* TODO */ },
                                onRegister = { navController.navigate("auth/register") },
                                onForgotPassword = { /* TODO */ }
                            )
                        }
                        composable("auth/register") {
                            RegisterScreen(onRegister = { /* TODO */ }, onBack = { navController.popBackStack() })
                        }
                        composable("home") { HomeScreen(navController) }
                        composable("tasks") { TasksScreen(navController) }
                        composable("tasks/add") { AddTaskScreen(navController) }
                        composable("social") { SocialScreen(navController) }
                        composable("social/search") { FriendSearchScreen(navController) }
                        composable("stats") { StatsScreen() }
                        composable("trophies") { TrophiesScreen() }
                        composable("account") { AccountScreen(navController) }
                        composable("account/edit") { EditProfileScreen() }
                        composable("account/subscribe") { SubscribeScreen(navController) }
                        composable("account/settings") { SettingsScreen() }
                        composable("account/privacy") { PrivacyScreen() }
                        composable("account/legal") { LegalScreen() }
                        composable("sessions") { StudySessionScreen(navController) }
                        composable("chatbot") { ChatBotScreen() }
                    }
                }
            }
        }
    }
}
