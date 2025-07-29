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
    var isStudying: [String]?
    var trophies: [String]?
    let friends: [String]?
    let pendingFriends: [String]?
    
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
        self.isStudying = nil
        self.trophies = []
        self.friends = nil
        self.pendingFriends = nil
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
        isStudying: [String]? = nil,
        trophies: [String]? = nil,
        lastConnection: Date? = nil,
        friends: [String]? = nil,
        pendingFriends: [String]? = nil
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
        self.isStudying = isStudying
        self.trophies = trophies
        self.friends = friends
        self.pendingFriends = pendingFriends
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
        // Store the FCM token under "fcm_token" in Firestore
        case fcmToken = "fcm_token"
        case isStudying = "is_studying"
        case trophies = "trophies"
        case lastConnection = "last_connection"
        case friends = "friends"
        case pendingFriends = "pending_friends"
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
        self.isStudying = try container.decodeIfPresent([String].self, forKey: .isStudying)
        self.trophies = try container.decodeIfPresent([String].self, forKey: .trophies)
        self.lastConnection = try container.decodeIfPresent(Date.self, forKey: .lastConnection)
        self.friends = try container.decodeIfPresent([String].self, forKey: .friends)
        self.pendingFriends = try container.decodeIfPresent([String].self, forKey: .pendingFriends)
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
        try container.encodeIfPresent(self.isStudying, forKey: .isStudying)
        try container.encodeIfPresent(self.trophies, forKey: .trophies)
        try container.encodeIfPresent(self.lastConnection, forKey: .lastConnection)
        try container.encodeIfPresent(self.friends, forKey: .friends)
        try container.encodeIfPresent(self.pendingFriends, forKey: .pendingFriends)
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
        self.isStudying = data[CodingKeys.isStudying.rawValue] as? [String]
        self.trophies = data[CodingKeys.trophies.rawValue] as? [String]
        self.friends = data[CodingKeys.friends.rawValue] as? [String]
        self.pendingFriends = data[CodingKeys.pendingFriends.rawValue] as? [String]
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
        if let isStudying = isStudying { dict[CodingKeys.isStudying.rawValue] = isStudying }
        if let trophies = trophies { dict[CodingKeys.trophies.rawValue] = trophies }
        if let lastConnection = lastConnection { dict[CodingKeys.lastConnection.rawValue] = Timestamp(date: lastConnection) }
        if let friends = friends { dict[CodingKeys.friends.rawValue] = friends }
        if let pendingFriends = pendingFriends { dict[CodingKeys.pendingFriends.rawValue] = pendingFriends }
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
        
        print("userid 2: \(userId)")
        
        try await userDocument(userId: userId).collection("work_sessions").addDocument(data: data)
    }

    func fetchStudySessions(userId: String) async throws -> [StudySession] {
        let snapshot = try await userDocument(userId: userId).collection("work_sessions").getDocuments()

        return snapshot.documents.compactMap { document in
            StudySession(document: document)
        }
    }

    func fetchRecentSessions(userId: String, days: Int) async throws -> [StudySession] {
        let cal = Calendar.current
        guard let cutoffDate = cal.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        let snapshot = try await userDocument(userId: userId)
            .collection("work_sessions")
            .whereField("session_start", isGreaterThanOrEqualTo: cutoffDate)
            .order(by: "session_start", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { StudySession(document: $0) }
    }

    /// Calculates the current work streak for the given user.
    /// - Returns: The number of consecutive days the user has worked up to **today**.
    ///   If the user hasn't worked today the streak will be `0`.
    func calculateStreak(userId: String) async throws -> Int {
        let sessions = try await fetchStudySessions(userId: userId)
        let cal = Calendar.current
        // Unique days a session was started on, sorted ascending
        let dayStarts = Set(sessions.map { cal.startOfDay(for: $0.session_start) }).sorted()
        guard let last = dayStarts.last, cal.isDateInToday(last) else { return 0 }

        var count = 1
        var prev = last
        for day in dayStarts.dropLast().reversed() {
            let diff = cal.dateComponents([.day], from: day, to: prev).day ?? 0
            if diff == 1 {
                count += 1
                prev = day
            } else if diff == 0 {
                continue
            } else {
                break
            }
        }
        return count
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

    func addTrophy(userId: String, trophy: String) async throws {
        try await userDocument(userId: userId).updateData([
            DBUser.CodingKeys.trophies.rawValue: FieldValue.arrayUnion([trophy])
        ])
    }

    func checkTenDayStreakTrophy(userId: String) async throws {
        let streak = try await calculateStreak(userId: userId)
        guard streak >= 10 else { return }
        let snapshot = try await userDocument(userId: userId).getDocument()
        let current = (snapshot.get(DBUser.CodingKeys.trophies.rawValue) as? [String]) ?? []
        if !current.contains("10_day_streak") {
            try await addTrophy(userId: userId, trophy: "10_day_streak")
        }
    }
    
    func saveFCMTokenToFirestore(token: String, userId: String) {
        
        print("FCM Token: \(token)")
        self.userDocument(userId: userId).updateData([
            DBUser.CodingKeys.fcmToken.rawValue: token
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
        try? await UserManager.shared.checkTenDayStreakTrophy(userId: userId)
        self.user = try await UserManager.shared.getUser(userId: userId)
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

extension DBUser: Identifiable {
    public var id: String { userId }
}

