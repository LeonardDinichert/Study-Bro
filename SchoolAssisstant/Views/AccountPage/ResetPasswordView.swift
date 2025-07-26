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
            VStack(spacing: 32) {
                Spacer(minLength: 80)
                
                // Header Section
                VStack(spacing: 8) {
                    Text("Forgot your Password?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("We'll send you an email with instructions on how to reset it.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Email Input Card
                VStack(spacing: 16) {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .fill(AppTheme.primaryColor)
                            )
                            .padding(.horizontal)
                    }
                }
                
                // Cancel Button
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryColor)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
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
