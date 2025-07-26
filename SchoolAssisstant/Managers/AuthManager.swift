//
//  AuthManager.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//

import Foundation
import FirebaseAuth
import Firebase
import AuthenticationServices

struct AuthDataResultModel: Identifiable {
    
    var id: String { uid }
    let uid: String
    let email: String?
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}

enum authProviderOption: String {
    
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}

final class AuthService {
    
    static let shared = AuthService()
    private init () {}
    
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse )
        }
        
        return AuthDataResultModel(user: user)
    }
    
    func getProviders() throws -> [authProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw URLError(.badServerResponse)
        }
        var providers: [authProviderOption] = []
        for provider in providerData {
            if let option = authProviderOption(rawValue: provider.providerID) {
                providers.append(option)
                
            } else {
                assertionFailure("Provider option not found \(provider.providerID)")
                
            }
        }
        return providers
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUserID() -> String {
        return Auth.auth().currentUser?.uid ?? "nil"
    }
    
    func deleteAccount(userId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        try await user.delete()
        //try await UserManager.shared.deleteUsersData(userId: userId)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    @discardableResult
    func signInWithApple(tokens: SigninWithAppleResult, appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: appleIDCredential.fullName)
        return try await signIn(credential: credential)
    }
    
    @discardableResult
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updatePassword(password: String) async throws {
        guard let user =  Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        try await user.updatePassword(to: password)
    }
    
    func updateEmail(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }

        // Send email verification before updating the email
        try await user.sendEmailVerification(beforeUpdatingEmail: email)
    }
}
