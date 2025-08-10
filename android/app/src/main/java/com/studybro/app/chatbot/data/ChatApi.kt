package com.studybro.app.chatbot.data

import com.studybro.app.chatbot.model.ChatMessage
import retrofit2.http.Body
import retrofit2.http.Headers
import retrofit2.http.POST

interface ChatApi {
    @Headers("Content-Type: application/json")
    @POST("v1/chat/completions")
    suspend fun chat(@Body request: ChatRequest): ChatResponse
}

data class ChatRequest(val model: String, val messages: List<ChatMessage>)

data class ChatChoice(val message: ChatMessage?)

data class ChatResponse(val choices: List<ChatChoice>)
