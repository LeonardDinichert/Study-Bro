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
            description: "Welcome to StuddyBuddy ! Here, you can learn more effectively and more easily. This app has been build with the lates psychlogy techniques and learniing methods to automate your learning.",
            systemImage: "sparkles",
            gradient: [Color.purple, Color.blue]
        ),
        IntroPage(
            title: "Use AI",
            description: "With the AI we created, you will be able to chat with it in order to understant some subject better. The provided context makes it more awares of your goals, what you want to learn or even how you do it.",
            systemImage: "brain.head.profile",
            gradient: [Color.indigo, Color.teal]
        ),
        IntroPage(
            title: "Stay Focused",
            description: "With lots of features all aiming to help you stay focuses and remember thing in short ot long term, this app gives you all teh chances for success in your studies.",
            systemImage: "timer",
            gradient: [Color.orange, Color.pink]
        )
    ]
}

