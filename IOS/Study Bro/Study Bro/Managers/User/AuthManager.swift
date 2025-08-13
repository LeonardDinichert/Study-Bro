//
//  AuthManager.swift
//  Study Bro
//
//  Created by Léonard Dinichert
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
        print("[AuthDataResultModel] Initialized with uid: \(uid), email: \(String(describing: email)), photoUrl: \(String(describing: photoUrl))")
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
            print("[AuthService] getAuthenticatedUser failed: No current user")
            throw URLError(.badServerResponse )
        }
        
        return AuthDataResultModel(user: user)
    }
    
    func getProviders() throws -> [authProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            print("[AuthService] getProviders failed: No provider data")
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
        do {
            try Auth.auth().signOut()
        } catch {
            print("[AuthService] signOut failed: \(error)")
            throw error
        }
    }
    
    func getCurrentUserID() -> String {
        return Auth.auth().currentUser?.uid ?? "nil"
    }
    
    func deleteAccount(userId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("[AuthService] deleteAccount failed: No current user")
            throw URLError(.badURL)
        }
        do {
            try await user.delete()
            //try await UserManager.shared.deleteUsersData(userId: userId)
        } catch {
            print("[AuthService] deleteAccount failed: \(error)")
            throw error
        }
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        print("[AuthService] Starting signIn with credential: \(credential)")
        do {
            let authDataResult = try await Auth.auth().signIn(with: credential)
            print("[AuthService] signIn succeeded for uid: \(authDataResult.user.uid)")
            return AuthDataResultModel(user: authDataResult.user)
        } catch {
            print("[AuthService] signIn failed: \(error)")
            throw error
        }
    }
    
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    @discardableResult
    func signInWithApple(tokens: SigninWithAppleResult, appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> AuthDataResultModel {
        print("[AuthService] signInWithApple called with token: \(tokens.token), nonce: \(tokens.nonce), fullName: \(String(describing: appleIDCredential.fullName))")
        let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: appleIDCredential.fullName)
        print("[AuthService] OAuthProvider.appleCredential created: \(credential)")
        do {
            let result = try await signIn(credential: credential)
            print("[AuthService] signInWithApple completed successfully for uid: \(result.uid)")
            return result
        } catch {
            print("[AuthService] signInWithApple failed: \(error)")
            throw error
        }
    }
    
    @discardableResult
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        do {
            let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
            return AuthDataResultModel(user: authDataResult.user)
        } catch {
            print("[AuthService] createUser failed: \(error)")
            throw error
        }
    }
    
    @discardableResult
    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        do {
            let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return AuthDataResultModel(user: authDataResult.user)
        } catch {
            print("[AuthService] signInUser failed: \(error)")
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            print("[AuthService] resetPassword failed: \(error)")
            throw error
        }
    }
    
    func updatePassword(password: String) async throws {
        guard let user =  Auth.auth().currentUser else {
            print("[AuthService] updatePassword failed: No current user")
            throw URLError(.badServerResponse)
        }
        do {
            try await user.updatePassword(to: password)
        } catch {
            print("[AuthService] updatePassword failed: \(error)")
            throw error
        }
    }
    
    func updateEmail(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("[AuthService] updateEmail failed: No current user")
            throw URLError(.badServerResponse)
        }

        do {
            // Send email verification before updating the email
            try await user.sendEmailVerification(beforeUpdatingEmail: email)
        } catch {
            print("[AuthService] updateEmail failed: \(error)")
            throw error
        }
    }
}
