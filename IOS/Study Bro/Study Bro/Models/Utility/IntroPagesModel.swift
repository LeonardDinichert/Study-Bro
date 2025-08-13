//
//  IntroPagesModel.swift
//  SchoolAssisstant
//
//  Created by OpenAI on 2025.
//

import SwiftUI

struct IntroPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let gradient: [Color]
}

struct IntroPagesModel {
    static let pages: [IntroPage] = [
        IntroPage(
            title: "Welcome",
            description: "Welcome to StuddyBuddy! Learn more effectively with modern psychology techniques and automated study helpers.",
            systemImage: "sparkles",
            gradient: [Color(hex: "#FF5F6D"), Color(hex: "#FFC371")]
        ),
        IntroPage(
            title: "Use AI",
            description: "Chat with our AI to better understand subjects. Context-aware conversations adapt to your goals and study style.",
            systemImage: "brain.head.profile",
            gradient: [Color(hex: "#2193b0"), Color(hex: "#6dd5ed")]
        ),
        IntroPage(
            title: "Stay Focused",
            description: "Stay on track with features designed to boost short- and long-term memory so you can succeed in your studies.",
            systemImage: "timer",
            gradient: [Color(hex: "#cc2b5e"), Color(hex: "#753a88")]
        )
    ]
}

