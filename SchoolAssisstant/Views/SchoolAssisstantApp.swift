//
//  SchoolAssisstantApp.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 07.04.2025.
//

import SwiftUI
import FirebaseCore

@main
struct SchoolAssisstantApp: App {
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
            IntroView()
        } else {
            MainInterfaceView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
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
    case tasks
    case progress
}
