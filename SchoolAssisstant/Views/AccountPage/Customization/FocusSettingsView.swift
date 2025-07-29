//
//  FocusSettingsView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 29.07.2025.
//

import SwiftUI
import AppIntents

struct FocusSettingsView: View {
    @AppStorage("autoActivateWorkFocus") private var autoActivateWorkFocus: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect()
                .shadow(radius: 16)
            VStack(spacing: 24) {
                Toggle("Auto-activate Work Focus during Pomodoro", isOn: $autoActivateWorkFocus)
                    .toggleStyle(.switch)
                if !autoActivateWorkFocus {
                    Text("When enabled, your iPhone will automatically enable the 'Work' Focus whenever a Pomodoro work session starts.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(32)
        }
        .padding()
        .background(Color.clear)
    }
}

#Preview {
    FocusSettingsView()
}
