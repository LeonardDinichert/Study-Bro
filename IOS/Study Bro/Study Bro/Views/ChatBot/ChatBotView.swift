import SwiftUI
import Foundation

struct ChatBotView: View {
    
    @StateObject private var viewModel = ChatBotViewModel()
    @FocusState private var isInputFocused: Bool
    @StateObject private var userViewModel = userManagerViewModel()
    @State private var wantsToGoPremium: Bool = false
    
    @AppStorage("showSignInView") private var showSignInView: Bool = true



    var body: some View {

            NavigationStack {
                if userViewModel.user != nil {
                    if userViewModel.user?.isPremium == true {
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
                    } else {
                        VStack(spacing: 16) {
                            Text("Only Study Pro users can use the AI capabilities of this app.")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("If you want to become premium click on this button.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                            
                            Button {
                                wantsToGoPremium = true
                            } label: {
                                Text("Go premium")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.accentColor)
                                    )
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.thinMaterial)
                                .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                        )
                        .padding()
                    }
                    
                }
                
                else {
                    VStack(spacing: 16) {
                        Text("Loading...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        ProgressView()
                            .font(.title)
                        
                        Text("If you are not logged in, you can log in below:")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        Button {
                            showSignInView = true
                        } label: {
                            Text("Sign in / Create an account")
                                .fontWeight(.semibold)
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.accentColor)
                                )
                        }
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.thinMaterial)
                            .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 6)
                    )
                    .padding()
                }
            }
            .onAppear() {
                Task {
                    try await userViewModel.loadCurrentUser()
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
            .fullScreenCover(isPresented: $wantsToGoPremium) {
                SubscribeView()
            }
        
    }
}
