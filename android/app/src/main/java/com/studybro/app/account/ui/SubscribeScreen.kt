package com.studybro.app.account.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.studybro.app.account.repo.SubscriptionRepository
import com.studybro.app.core.di.FirebaseModule
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.rememberPaymentSheet
import kotlinx.coroutines.launch

@Composable
fun SubscribeScreen(navController: NavController, repo: SubscriptionRepository = SubscriptionRepository()) {
    val scope = rememberCoroutineScope()
    val paymentSheet = rememberPaymentSheet { result ->
        if (result is PaymentSheet.Result.Completed) {
            val uid = FirebaseModule.auth.currentUser?.uid ?: return@rememberPaymentSheet
            FirebaseModule.firestore.collection("users").document(uid).update("premium", true)
            navController.popBackStack()
        }
    }
    Column(modifier = Modifier.fillMaxWidth()) {
        Text("Subscribe for premium features")
        Button(onClick = {
            scope.launch {
                try {
                    val resp = repo.createSubscription()
                    val config = PaymentSheet.Configuration(
                        merchantDisplayName = "StudyBro",
                        customer = if (resp.customer != null && resp.ephemeralKey != null) {
                            PaymentSheet.CustomerConfiguration(resp.customer, resp.ephemeralKey)
                        } else null
                    )
                    resp.paymentIntentClientSecret?.let { secret ->
                        paymentSheet.presentWithPaymentIntent(secret, config)
                    } ?: resp.setupIntentClientSecret?.let { secret ->
                        paymentSheet.presentWithSetupIntent(secret, config)
                    }
                } catch (e: Exception) {
                    // TODO show error
                }
            }
        }) { Text("Subscribe") }
    }
}
