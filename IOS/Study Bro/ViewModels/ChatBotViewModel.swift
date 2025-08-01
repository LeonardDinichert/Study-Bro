import Foundation
import SwiftUI

// Model for chat messages (UI)
struct ChatMessageModel: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

@MainActor
final class ChatBotViewModel: ObservableObject {
    @Published var messages: [ChatMessageModel] = []
    @Published var inputText: String = ""

    // MARK: - Configuration
    private let apiToken = "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"
    private let modelID = "meta-llama/Llama-3.1-8B-Instruct:cerebras"

    // MARK: - Public API
    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Append user message
        let userMsg = ChatMessageModel(text: trimmed, isUser: true)
        messages.append(userMsg)
        inputText = ""

        // Fetch bot reply
        let responseText = await fetchReply(for: trimmed)
        let botMsg = ChatMessageModel(text: responseText, isUser: false)
        messages.append(botMsg)
    }

    // MARK: - Networking

    /// OpenAI-style chat request body
    private struct HFChatRequest: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
        var max_tokens: Int? = 300
        var stream: Bool = false
    }

    /// Decoded response from Hugging Face chat endpoint
    private struct HFChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let role: String
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    /// Calls `https://router.huggingface.co/v1/chat/completions`
    private func fetchReply(for prompt: String) async -> String {
        // Build URL
        guard let url = URL(string: "https://router.huggingface.co/v1/chat/completions") else {
            return "Invalid URL"
        }

        // Build HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        let body = HFChatRequest(
            model: modelID,
            messages: [
                .init(role: "system", content: "You are a helpful assistant."),
                .init(role: "user",   content: prompt)
            ]
        )
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return "Encoding error"
        }

        // Perform call
        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                return "API error: \(code)"
            }
            // Decode
            let decoded = try JSONDecoder().decode(HFChatResponse.self, from: data)
            return decoded.choices.first?.message.content
                ?? "No response"
        } catch {
            return "Network error: \(error.localizedDescription)"
        }
    }
}
