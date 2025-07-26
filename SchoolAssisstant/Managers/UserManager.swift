//
//  userManager.swift
//
//
//  Created by Léonard Dinichert on 10.04.25.
//

import Foundation
import FirebaseFirestore
import PhotosUI
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseMessaging

struct DBUser: Codable {
    // MARK: - Properties
    
    let userId: String
    let email: String?
    let age: Int?
    let username: String?
    let firstName: String?
    let lastName: String?
    let profileImagePathUrl: String?
    let biography: String?
    let lastConnection: Date?
    var fcmToken: String?
    
    // MARK: - Initializers
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.age = nil
        self.firstName = nil
        self.lastName = nil
        self.username = nil
        self.profileImagePathUrl = nil
        self.biography = nil
        self.lastConnection = nil
        self.fcmToken = nil
    }
    
    init(
        userId: String,
        email: String? = nil,
        age: Int? = nil,
        username: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        profileImagePathUrl: String? = nil,
        biography: String? = nil,
        fcmToken: String? = nil,
        lastConnection: Date? = nil
    ) {
        self.userId = userId
        self.email = email
        self.age = age
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.profileImagePathUrl = profileImagePathUrl
        self.biography = biography
        self.lastConnection = lastConnection
        self.fcmToken = fcmToken
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case age = "age"
        case username = "username"
        case firstName = "first_name"
        case lastName = "last_name"
        case profileImagePathUrl = "profile_image_path_url"
        case biography = "biography"
        case fcmToken = "fcmToken" // Coding Key for FCM Token
        case lastConnection = "last_connection"
    }
    
    // MARK: - Decoder Initializer
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.age = try container.decodeIfPresent(Int.self, forKey: .age)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.profileImagePathUrl = try container.decodeIfPresent(String.self, forKey: .profileImagePathUrl)
        self.biography = try container.decodeIfPresent(String.self, forKey: .biography)
        self.fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        self.lastConnection = try container.decodeIfPresent(Date.self, forKey: .lastConnection)
    }
    
    // MARK: - Encoder Method
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.username, forKey: .username)
        try container.encodeIfPresent(self.firstName, forKey: .firstName)
        try container.encodeIfPresent(self.lastName, forKey: .lastName)
        try container.encodeIfPresent(self.age, forKey: .age)
        try container.encodeIfPresent(self.profileImagePathUrl, forKey: .profileImagePathUrl)
        try container.encodeIfPresent(self.biography, forKey: .biography)
        try container.encodeIfPresent(self.fcmToken, forKey: .fcmToken)
        try container.encodeIfPresent(self.lastConnection, forKey: .lastConnection)
    }

    init?(id: String, data: [String: Any]) {
        self.userId = id
        self.email = data[CodingKeys.email.rawValue] as? String
        self.age = data[CodingKeys.age.rawValue] as? Int
        self.username = data[CodingKeys.username.rawValue] as? String
        self.firstName = data[CodingKeys.firstName.rawValue] as? String
        self.lastName = data[CodingKeys.lastName.rawValue] as? String
        self.profileImagePathUrl = data[CodingKeys.profileImagePathUrl.rawValue] as? String
        self.biography = data[CodingKeys.biography.rawValue] as? String
        self.fcmToken = data[CodingKeys.fcmToken.rawValue] as? String
        if let ts = data[CodingKeys.lastConnection.rawValue] as? Timestamp {
            self.lastConnection = ts.dateValue()
        } else {
            self.lastConnection = nil
        }
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            CodingKeys.userId.rawValue: userId
        ]
        if let email = email { dict[CodingKeys.email.rawValue] = email }
        if let age = age { dict[CodingKeys.age.rawValue] = age }
        if let username = username { dict[CodingKeys.username.rawValue] = username }
        if let firstName = firstName { dict[CodingKeys.firstName.rawValue] = firstName }
        if let lastName = lastName { dict[CodingKeys.lastName.rawValue] = lastName }
        if let profileImagePathUrl = profileImagePathUrl { dict[CodingKeys.profileImagePathUrl.rawValue] = profileImagePathUrl }
        if let biography = biography { dict[CodingKeys.biography.rawValue] = biography }
        if let fcmToken = fcmToken { dict[CodingKeys.fcmToken.rawValue] = fcmToken }
        if let lastConnection = lastConnection { dict[CodingKeys.lastConnection.rawValue] = Timestamp(date: lastConnection) }
        return dict
    }
}

final class UserManager: ObservableObject {
    
    // MARK: - Singleton Instance
    
    static let shared = UserManager()
    private init() {}
    
    // MARK: - Firestore References
    
    let userCollection = Firestore.firestore().collection("users")
    
    func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    // MARK: - Authentication Properties
    
    @Published var currentUser: DBUser? = nil
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Firestore User Data Management
    
    func createNewUser(user: DBUser) async throws {
        try await userDocument(userId: user.userId).setData(user.dictionary, merge: false)
    }
    
    func deleteUsersData(userId: String) async throws {
        try await userDocument(userId: userId).delete()
    }
    
    func getUser(userId: String) async throws -> DBUser {
        let snapshot = try await userDocument(userId: userId).getDocument()
        guard let data = snapshot.data() else {
            throw NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        guard let user = DBUser(id: snapshot.documentID, data: data) else {
            throw NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        return user
    }
    
    func getAllUsers() async throws -> [DBUser] {
        let querySnapshot = try await userCollection.getDocuments()
        return querySnapshot.documents.compactMap { doc in
            DBUser(id: doc.documentID, data: doc.data())
        }
    }
    
    func updateUserInfo(userId: String, firstName: String, lastName: String, birthDate: Date, username: String) async throws {
        let data: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "username": username,
            "birthdate": birthDate,
        ]
        
        try await userDocument(userId: userId).setData(data, merge: true)
    }
    
    func updateUserAdress(userId: String, adress: String) async throws {
        let data: [String: Any] = [
            "adress": adress
        ]

        try await userDocument(userId: userId).setData(data, merge: true)
    }

    func updateUsername(userId: String, username: String) async throws {
        try await userDocument(userId: userId).setData(["username": username], merge: true)
    }
    
    func addStudySessionRegisteredToUser(userId: String, studiedSubject: String, start: Date, end: Date) async throws {
        let data: [String: Any] = [
            "id": userId,
            "session_start": start,
            "session_end": end,
            "studied_subject": studiedSubject
        ]
        
        try await userDocument(userId: userId).collection("work_sessions").addDocument(data: data)
    }

    func fetchStudySessions(userId: String) async throws -> [StudySession] {
        let snapshot = try await userDocument(userId: userId).collection("work_sessions").getDocuments()

        return snapshot.documents.compactMap { document in
            StudySession(document: document)
        }
    }
    

    
    func loadCurrentUserId() async throws -> String {
        
        let userId = Auth.auth().currentUser?.uid ?? "none"
        return userId
    }
    
    func updateUserProfileImagePathUrl(userId: String, path: String?, url: String?) async throws {
        let data: [String: Any] = [
            DBUser.CodingKeys.profileImagePathUrl.rawValue: url ?? "no path",
        ]
        
        try await userDocument(userId: userId).updateData(data)
    }
    
    func saveFCMTokenToFirestore(token: String, userId: String) {
        
        print("FCM Token: \(token)")
        self.userDocument(userId: userId).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error saving FCM token to Firestore: \(error)")
            } else {
                print("FCM token successfully saved to Firestore")
            }
        }
    }

    func updateLastConnection(userId: String, date: Date) async throws {
        try await userDocument(userId: userId).setData([
            DBUser.CodingKeys.lastConnection.rawValue: Timestamp(date: date)
        ], merge: true)
    }
}

// MARK: - UserManagerViewModel

@MainActor
final class userManagerViewModel: ObservableObject {

    @Published private(set) var user: DBUser? = nil
    @Published var leaderboard: [DBUser] = []
    @AppStorage("useDarkMode") var useDarkMode: Bool = false
    
    let userCollection = Firestore.firestore().collection("users")
    
    func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func loadCurrentUser() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user.")
            return
        }
    
        self.user = try await UserManager.shared.getUser(userId: userId)
        try? await UserManager.shared.updateLastConnection(userId: userId, date: Date())
    }
    
    func sendNotificationRequest(title: String, body: String, token: String? = nil) {
        guard let url = URL(string: "https://us-central1-jobb-8f5e7.cloudfunctions.net/sendPushNotification") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Retrieve the FCM token from UserManager
        let targetToken = token ?? user?.fcmToken
        guard let fcmToken = targetToken else {
            print("FCM token not found (UserManagerViewModel sendNotificationRequest)")
            return
        }

        let bodyData: [String: Any] = [
            "token": fcmToken,
            "title": title,
            "body": body
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification request: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("Notification request sent successfully")
                } else {
                    print("Server error: \(httpResponse.statusCode)")
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("Error message: \(errorMessage)")
                    }
                }
            }
        }
        task.resume()
    }

    func loadLeaderboard() async {
        do {
            leaderboard = try await UserManager.shared.getAllUsers()
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
    }
    
    func saveProfileImage(data: Data, userId: String) async throws {
        let (path, name) = try await StorageManager.shared.saveImage(data: data, userId: userId)
        print("SUCCESS in saving image!")
        print("Path: \(path)")
        print("Name: \(name)")
        let url = try await StorageManager.shared.getUrlForImage(path: path)
        try await UserManager.shared.updateUserProfileImagePathUrl(userId: userId, path: path, url: url.absoluteString)
    }
    
    func deleteProfileImage() {
        guard let user = user, let path = user.profileImagePathUrl else { return }
        
        Task {
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePathUrl(userId: user.userId, path: nil, url: nil)
        }
    }
}

