import Foundation
import SwiftUI

// Model for chat messages

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
    private let apiToken = "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" // Replace with your token
    private let modelID = "gpt2"          // Or another HF model ID

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
    /// Calls the Hugging Face Inference API and returns the generated text.
    private func fetchReply(for prompt: String) async -> String {
        struct HFRequest: Encodable { let inputs: String }
        struct HFChoice: Decodable { let generated_text: String }

        // Construct URL
        guard let url = URL(string: "https://api-inference.huggingface.co/models/\(modelID)") else {
            return "Invalid API URL"
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(HFRequest(inputs: prompt))

        // Perform network call
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return "Error: Bad response (\((response as? HTTPURLResponse)?.statusCode ?? 0))"
            }
            // Decode generated text
            if let choice = try? JSONDecoder().decode([HFChoice].self, from: data).first {
                return choice.generated_text
            } else {
                return "Error: Unable to parse response"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
