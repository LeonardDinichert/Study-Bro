package com.studybro.app.chatbot.vm

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.studybro.app.chatbot.data.ChatApi
import com.studybro.app.chatbot.data.ChatRequest
import com.studybro.app.chatbot.model.ChatMessage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory

class ChatBotViewModel : ViewModel() {
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages

    private val key = "" // TODO HUGGINGFACE_API_KEY
    private val model = "" // TODO HUGGINGFACE_MODEL

    private val api: ChatApi by lazy {
        val moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
        val client = OkHttpClient.Builder().addInterceptor { chain ->
            val req = chain.request().newBuilder().apply {
                if (key.isNotEmpty()) header("Authorization", "Bearer $key")
            }.build()
            chain.proceed(req)
        }.build()
        Retrofit.Builder()
            .baseUrl("https://router.huggingface.co/")
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .client(client)
            .build()
            .create(ChatApi::class.java)
    }

    fun sendMessage(text: String) {
        _messages.value = _messages.value + ChatMessage("user", text)
        viewModelScope.launch {
            try {
                val resp = api.chat(ChatRequest(model, _messages.value))
                val msg = resp.choices.firstOrNull()?.message
                if (msg != null) {
                    _messages.value = _messages.value + msg
                }
            } catch (e: Exception) {
                _messages.value = _messages.value + ChatMessage("assistant", "Error: ${e.localizedMessage}")
            }
        }
    }
}
