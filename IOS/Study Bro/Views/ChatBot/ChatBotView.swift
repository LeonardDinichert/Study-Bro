import SwiftUI
import Foundation

struct ChatBotView: View {
    
    @StateObject private var viewModel = ChatBotViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {

            NavigationStack {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(viewModel.messages) { msg in
                                    HStack {
                                        if msg.isUser { Spacer() }
                                        Text(msg.text)
                                            .foregroundColor(msg.isUser ? .primary : .primary)
                                            .padding()
                                            .glassEffect()
                                            
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
                            
                            HStack (spacing: 10){
                                
                                CustomTextField(text: $viewModel.inputText, placeholder: "Write something to AI")
                                    .focused($isInputFocused)
                                    .padding(.horizontal)
                                    .cornerRadius(18)
                                    .frame(height: 50)
                                
                                
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
                                .padding(.leading)
                                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                
                            }
                            .glassEffect()

                           
 
                        }


                        if isInputFocused {
                            Button(action: { isInputFocused = false }) {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .padding([.horizontal, .bottom])
                }
                .navigationTitle("Chatbot")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
        }
    }
}
