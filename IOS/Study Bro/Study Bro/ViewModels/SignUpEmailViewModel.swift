//
//  EmailViewModel.swift
//  Jobb
//
//  Created by Léonard Dinichert on 10.07.23.
//

import SwiftUI
import CryptoKit
import AuthenticationServices
import Combine

@MainActor
final class SignUpEmailViewModel: NSObject, ObservableObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No UIWindowScene found for presentation anchor. Unable to provide ASPresentationAnchor.")
        }
        return ASPresentationAnchor(windowScene: windowScene)
    }
    
    @AppStorage("showSignInView") private var showSignInView: Bool = true
    
    @Published var email : String = ""
    @Published var password : String = ""
    @State var appleVM = AppleSignInViewModel()
    @Published var errorMessage = ""

        
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "The email or the password misses"
            throw NSError(domain: "SignUpEmailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        let authDataResult = try await AuthService.shared.createUser(email: email, password: password)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "No email or password found."
            throw NSError(domain: "SignUpEmailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        _ = try await AuthService.shared.signInUser(email: email, password: password)
    }
}

