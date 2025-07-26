//
//  IntroPagesModel.swift
//  SchoolAssisstant
//
//  Created by OpenAI on 2025.
//

import Foundation

struct IntroPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
}

struct IntroPagesModel {
    static let pages: [IntroPage] = [
        IntroPage(title: "Welcome", description: "Manage your school tasks easily.", systemImage: "star"),
        IntroPage(title: "Track Progress", description: "Keep track of what you've learned.", systemImage: "list.bullet.rectangle"),
        IntroPage(title: "Stay Focused", description: "Use timers to stay productive.", systemImage: "timer")
    ]
}

