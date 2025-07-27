import SwiftUI
import Foundation

struct ChatBotView: View {
    @StateObject private var viewModel: ChatBotViewModel
    
    init() {
        let welcome = ChatMessageModel(text: "Welcome to ChatBot! How can I assist you today?", isUser: false)
        _viewModel = StateObject(wrappedValue: ChatBotViewModel())
        _viewModel.wrappedValue.messages.append(welcome)
    }
    
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Liquid‐glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            NavigationStack {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(viewModel.messages) { msg in
                                    HStack {
                                        if msg.isUser { Spacer() }
                                        Text(msg.text)
                                            .foregroundColor(msg.isUser ? .white : .primary)
                                            .padding(10)
                                            .background(
                                                msg.isUser
                                                    ? AppTheme.primaryTint.opacity(0.7)
                                                    : Color(.secondarySystemBackground).opacity(0.6)
                                            )
                                            .glassEffect()
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        if !msg.isUser { Spacer() }
                                    }
                                    .frame(maxWidth: .infinity,
                                           alignment: msg.isUser ? .trailing : .leading)
                                    .id(msg.id)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .padding(.top, 16)

                    // Input area
                    HStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            if viewModel.inputText.isEmpty {
                                Text("yes")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                            }
                            CustomTextField(text: $viewModel.inputText, placeholder: "Write something to AI")
                                .focused($isInputFocused)
                                .padding(.horizontal)
                                .cornerRadius(18)
                                .glassEffect()
                                .frame(height: 50)
 
                        }

                        Button {
                            isInputFocused = false
                            Task { await viewModel.sendMessage() }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(
                                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? .gray
                                        : AppTheme.primaryColor
                                )
                        }
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if isInputFocused {
                            Button(action: { isInputFocused = false }) {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding([.horizontal, .bottom])
                }
                .navigationTitle("Chatbot")
                .background(Color.clear)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
        }
    }
}

#Preview {
    ChatBotView()
}
