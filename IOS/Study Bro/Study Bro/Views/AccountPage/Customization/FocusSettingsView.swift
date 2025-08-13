//
//  FocusSettingsView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI
import UserNotifications
import UIKit

struct FocusSettingsView: View {
    @State private var showShortcutHelp = false
    private let shortcutName = "Work Focus On" // user must create this once
    private let workFocusShortcutShareURL = URL(string: "https://www.icloud.com/shortcuts/7bb50f6efa4f43dbab7a31b554dfc43c")!


    var body: some View {
        NavigationStack {
            List {
                Section("What happens") {
                    Text("• Tap the button → runs your Shortcut to enable Work Focus.\n• Also silences this app: clears notifications and stops remote pushes.\n• Optionally open Notification settings to turn off alerts for this app.")
                        .font(.subheadline)
                }
                
                Section("One-time setup") {
                    Text("1) In Shortcuts: New → Add Action → Set Focus → Work → Until turned off. Name it “\(shortcutName)”.")
                    VStack {
                        Button {
                            UIApplication.shared.open(workFocusShortcutShareURL)
                        } label: {
                            Label("Add “Work Focus On” Shortcut", systemImage: "plus.circle.fill")
                        }
                        
                        Button {
                            QuietMode.trigger(shortcutName: shortcutName)
                        } label: {
                            Label("Enable Work Focus & Silence", systemImage: "moon.zzz.fill")
                        }
                    }
                    Text("2) (Optional) Auto-activate when this app opens:\nSettings → Focus → Work → Add Schedule → App → select this app.")
                        .font(.footnote)
                }

                Section("Use it") {
                    Button("Enable Work Focus now") { runWorkFocusShortcut() }
                    Button("Open app Notification settings") { openAppNotificationSettings() }
                }

                Section("Notes") {
                    Text("iOS won’t let apps toggle Focus or mute other apps. This method uses your Shortcut + app-only controls.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                            QuietMode.trigger(shortcutName: shortcutName)
                        } label: {
                            Label("Enable Work Focus & Silence", systemImage: "moon.zzz.fill")
                        }
            }
            .navigationTitle("Quiet Mode")
            .alert("Create the Shortcut first",
                   isPresented: $showShortcutHelp,
                   actions: {
                       Button("Open Shortcuts") { openURL("shortcuts://") }
                       Button("OK", role: .cancel) { }
                   },
                   message: {
                       Text("Make a shortcut named “\(shortcutName)” with the action: Set Focus → Work → Until turned off.")
                   })
        }
    }

    // MARK: - Actions

    private func runWorkFocusShortcut() {
        let encoded = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        guard let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            // Also silence this app immediately
            NotificationSilencer.silenceMost()
        } else {
            showShortcutHelp = true
        }
    }

    private func openAppNotificationSettings() {
        let urlString: String
        if #available(iOS 16.0, *) {
            urlString = UIApplication.openNotificationSettingsURLString
        } else {
            urlString = UIApplication.openSettingsURLString
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

enum NotificationSilencer {
    static func silenceMost() {
        // Clear local & delivered notifications (this app only)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // Stop receiving remote pushes for this app until re-registered
        UIApplication.shared.unregisterForRemoteNotifications()
    }
}

enum QuietMode {
    static func trigger(shortcutName: String) {
        // Run the Shortcut that sets Work Focus
        let encoded = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        if let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") {
            UIApplication.shared.open(url) // iOS Shortcuts URL scheme
        }

        // Silence this app’s notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        UIApplication.shared.unregisterForRemoteNotifications()
    }
}
