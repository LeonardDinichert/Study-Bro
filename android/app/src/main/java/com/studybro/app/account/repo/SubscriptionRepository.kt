package com.studybro.app.account.repo

import retrofit2.http.POST
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient

interface SubscriptionApi {
    @POST("create-subscription")
    suspend fun createSubscription(): SubscriptionResponse
}

data class SubscriptionResponse(
    val paymentIntentClientSecret: String? = null,
    val setupIntentClientSecret: String? = null,
    val customer: String? = null,
    val ephemeralKey: String? = null
)

class SubscriptionRepository {
    private val backend = "" // TODO SUBSCRIPTION_BACKEND_URL
    private val api: SubscriptionApi by lazy {
        val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
        Retrofit.Builder()
            .baseUrl(backend)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .client(OkHttpClient.Builder().build())
            .build()
            .create(SubscriptionApi::class.java)
    }

    suspend fun createSubscription(): SubscriptionResponse = api.createSubscription()
}
