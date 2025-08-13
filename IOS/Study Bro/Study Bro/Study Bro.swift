//
//  SchoolAssisstantApp.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import UserNotifications
import StripePaymentSheet

@main
struct StudyBro: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            HasSeenWelcomingMessage()
                .tint(AppTheme.primaryColor)
        }
    }
}
    

struct HasSeenWelcomingMessage: View {
    
    @AppStorage("hasShownWelcome") private var hasShownWelcome: Bool = false
    
    var body: some View {
        
        if !hasShownWelcome {
            IntroPagesView()
        } else {
            MainInterfaceView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate,
                   UNUserNotificationCenterDelegate, MessagingDelegate {
    
    

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        StripeAPI.defaultPublishableKey = "pk_test_51RtVPCAgKukMvTmDbG8vNZCcJN2gEt3WEyTGGXLZtCYMH0PFm9OrjfGaxQ5HZ8ln0c71iH4w4YcBiVA0LQ9ubFdG00uzQ2gIi2"

        // Notification center delegate
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()

        // FCM delegate & initial token fetch
        Messaging.messaging().delegate = self
        Messaging.messaging().token { token, error in
            guard let token = token, error == nil else { return }
            if let uid = Auth.auth().currentUser?.uid {
                UserManager.shared.saveFCMTokenToFirestore(token: token, userId: uid)
            }
        }

        return true
    }

    // MARK: - APNs Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Link APNs token with FCM
        Messaging.messaging().apnsToken = deviceToken  // :contentReference[oaicite:10]{index=10}
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Log any registration errors
        print("APNs registration failed: \(error)")  // :contentReference[oaicite:11]{index=11}
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show alert, badge, sound even in foreground
        completionHandler([.banner, .list, .badge, .sound])  // :contentReference[oaicite:12]{index=12}
    }

    // Handle user interaction with the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("Tapped notification with userInfo:", userInfo)  // :contentReference[oaicite:13]{index=13}
        completionHandler()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken,
              let uid = Auth.auth().currentUser?.uid else { return }
        UserManager.shared.saveFCMTokenToFirestore(token: token, userId: uid)  // :contentReference[oaicite:14]{index=14}
    }
}


struct MainInterfaceView: View {

    @AppStorage("showSignInView") private var showSignInView = true
    @AppStorage("useDarkMode") private var useDarkMode = false
    @State private var selectedTab: Tab = .home
    @State private var haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        if showSignInView {
            AuthenticationView()
        } else {
            TabView(selection: $selectedTab) {
                HomeTab(selectedTab: $selectedTab)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.home)

                StudySessionView()
                    .tabItem { Label("Study", systemImage: "pencil.and.outline") }
                    .tag(Tab.studySession)

//                TasksTab()
//                    .tabItem { Label("Tasks", systemImage: "list.bullet") }
//                    .tag(Tab.tasks)

//                GamificationView()
//                    .tabItem { Label("Progress", systemImage: "star.fill") }
//                    .tag(Tab.progress)
                ChatBotView()
                    .tabItem { Label("Chat", systemImage: "message.fill") }
                    .tag(Tab.chatbot)
                

                LearnedSomethingView()
                    .tabItem { Label("Learn", systemImage: "graduationcap.fill") }
                    .tag(Tab.learnedSomething)

                

                AccountTab()
                    .tabItem { Label("Account", systemImage: "person.fill") }
                    .tag(Tab.account)
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: selectedTab) {
                haptic.impactOccurred()
            }
        }
    }
}

enum Tab {
    case home
    case account
    case studySession
    case social
    case learnedSomething
    case chatbot
    case tasks
    case progress
}

