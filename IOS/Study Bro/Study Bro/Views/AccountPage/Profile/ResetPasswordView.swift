import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var alertIsShown = false
    @State private var errString: String?
    
    @StateObject private var settingsVm = SettingViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient with blur
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // Icon
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue.gradient)
                        .shadow(radius: 8)
                        .padding(.bottom, 8)

                    // Header Section
                    VStack(spacing: 8) {
                        Text("Forgot your Password?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .shadow(color: Color.blue.opacity(0.09), radius: 2, x: 0, y: 2)
                        Text("We'll send you an email with instructions on how to reset it.")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // Email Input Card
                    VStack(spacing: 16) {
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 2)
                        Button {
                            Task {
                                do {
                                    try await settingsVm.resetPassword(email: email)
                                } catch {
                                    errString = error.localizedDescription
                                    alertIsShown = true
                                }
                            }
                        } label: {
                            Text("Next")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [AppTheme.primaryColor, .blue]), startPoint: .leading, endPoint: .trailing)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                )
                                .shadow(color: AppTheme.primaryColor.opacity(0.24), radius: 5, x: 0, y: 2)
                                .padding(.horizontal, 2)
                        }
                    }
                    .padding(.vertical, 25)
                    .padding(.horizontal, 18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .primary.opacity(0.13), radius: 14, x: 0, y: 9)
                    .padding(.horizontal, 6)

                    // Cancel Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryColor)
                            .padding(8)
                    }
                    .background(Color.clear)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $alertIsShown) {
                Alert(
                    title: Text("Password reset"),
                    message: Text(errString ?? "Success. Reset Email sent successfully. Check your emails."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView()
    }
}

