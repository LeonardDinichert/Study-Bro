//
//  SignInWithApple.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import CryptoKit
import AuthenticationServices
import Combine

class AppleSignInViewModel: NSObject, ObservableObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate  {
    
    @Published var didSignInWithApple: Bool = false
    
    private var currentNonce: String?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("[SignInWithApple] presentationAnchor: called")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback: if no window, but a windowScene exists, use the scene itself.
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                print("[SignInWithApple] presentationAnchor: no key window found, returning ASPresentationAnchor with windowScene")
                return ASPresentationAnchor(windowScene: windowScene)
            }
            // If no windowScene at all, fatalError or return a zero anchor as last resort
            fatalError("No UIWindowScene found for ASPresentationAnchor.")
        }
        print("[SignInWithApple] presentationAnchor: returning key window \(window)")
        return window
    }
    
    
    func startSignInWithAppleFlow() {
        print("[SignInWithApple] startSignInWithAppleFlow: called")
        let nonce = randomNonceString()
        print("[SignInWithApple] startSignInWithAppleFlow: generated nonce: \(nonce)")
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        print("[SignInWithApple] startSignInWithAppleFlow: created request")
        request.requestedScopes = [.fullName, .email]
        print("[SignInWithApple] startSignInWithAppleFlow: set requestedScopes to [.fullName, .email]")
        request.nonce = sha256(nonce)
        print("[SignInWithApple] startSignInWithAppleFlow: set request.nonce to sha256 of nonce")
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        print("[SignInWithApple] startSignInWithAppleFlow: performing authorization requests")
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        print("[SignInWithApple] randomNonceString: called with length = \(length)")
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        let nonceString = String(nonce)
        print("[SignInWithApple] randomNonceString: generated nonce string: \(nonceString)")
        return nonceString
    }
    
    private func sha256(_ input: String) -> String {
        print("[SignInWithApple] sha256: called with input: \(input)")
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        print("[SignInWithApple] sha256: generated hash string: \(hashString)")
        return hashString
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("[SignInWithApple] authorizationController(didCompleteWithAuthorization): called")
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8),
            let nonce = currentNonce else {
            print("[SignInWithApple] authorizationController(didCompleteWithAuthorization): error - missing credentials or nonce")
            return
        }
        print("[SignInWithApple] authorizationController(didCompleteWithAuthorization): extracted appleIDCredential, idTokenString: \(idTokenString), nonce: \(nonce)")
        
        let tokens = SigninWithAppleResult(token: idTokenString, nonce: nonce)
        
        Task {
            do {
                try await AuthService.shared.signInWithApple(tokens: tokens, appleIDCredential: appleIDCredential)
                print("[SignInWithApple] authorizationController(didCompleteWithAuthorization): signInWithApple succeeded")
                // Ensure state update is on the main thread for UI synchronization
                Task { @MainActor in
                    self.didSignInWithApple = true
                }
            } catch {
                print("[SignInWithApple] authorizationController(didCompleteWithAuthorization): signInWithApple failed with error: \(error)")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("[SignInWithApple] authorizationController(didCompleteWithError): Sign in with Apple errored: \(error)")
    }
    
    func signUpWithApple() async {
        print("[SignInWithApple] signUpWithApple: called")
        startSignInWithAppleFlow()
    }
}

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onTap: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        print("[SignInWithApple] SignInWithAppleButtonViewRepresentable.makeUIView: called")
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        print("[SignInWithApple] SignInWithAppleButtonViewRepresentable.updateUIView: called")
    }
    
    class Coordinator: NSObject {
        let onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap() {
            print("[SignInWithApple] Coordinator.handleTap: button tapped")
            onTap()
        }
    }
}

struct SigninWithAppleResult {
    let token: String
    let nonce: String
    
    init(token: String, nonce: String) {
        self.token = token
        self.nonce = nonce
        print("[SignInWithApple] SigninWithAppleResult.init: token: \(token), nonce: \(nonce)")
    }
}

/*
 Usage example:
 
 struct ContentView: View {
     @StateObject private var viewModel = AppleSignInViewModel()
     
     var body: some View {
         SignInWithAppleButtonViewRepresentable(type: .signIn, style: .black, onTap: {
             viewModel.signUpWithApple()
         })
         .frame(height: 45)
     }
 }
 
 */

