import Foundation

@MainActor
final class ChatBotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMsg = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMsg)
        inputText = ""

        let response = await fetchReply(for: trimmed)
        let botMsg = ChatMessage(text: response, isUser: false)
        messages.append(botMsg)
    }

    /// Call the HuggingFace inference API and return the generated text.
    /// Replace the placeholder URL and token with your own settings.
    private func fetchReply(for prompt: String) async -> String {
        struct HFRequest: Encodable { let inputs: String }
        struct HFChoice: Decodable { let generated_text: String }

        guard let url = URL(string: "https://api-inference.huggingface.co/models/YOUR_MODEL") else {
            return "Invalid API URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer YOUR_HF_TOKEN", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(HFRequest(inputs: prompt))

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let choice = try? JSONDecoder().decode([HFChoice].self, from: data).first {
                return choice.generated_text
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }

        return "No response"
    }
}
