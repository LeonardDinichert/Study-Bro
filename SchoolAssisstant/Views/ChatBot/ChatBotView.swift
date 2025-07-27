import SwiftUI
import Foundation

struct ChatBotView: View {
    @StateObject private var viewModel = ChatBotViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Glass background
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
                                            .background(msg.isUser ? AppTheme.primaryTint.opacity(0.7) : Color(.secondarySystemBackground).opacity(0.6))
                                            .glassEffect()
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        if !msg.isUser { Spacer() }
                                    }
                                    .frame(maxWidth: .infinity, alignment: msg.isUser ? .trailing : .leading)
                                    .id(msg.id)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                    }
                    .padding(.top, 16)

                    // Input area with glass and clean style
                    HStack(spacing: 8) {
                        GrowingTextEditor(text: $viewModel.inputText)
                            .frame(minHeight: 36)
                            .padding(8)
                            .background(Color(.secondarySystemBackground).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .focused($isInputFocused)
                        Button {
                            isInputFocused = false
                            Task { await viewModel.sendMessage() }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : AppTheme.primaryColor)
                        }
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        // Hide Keyboard Button
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
