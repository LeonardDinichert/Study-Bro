//
//  JobIntroView.swift
//  SchoolAssisstant
//
//  Created by OpenAI on 2025.
//

import SwiftUI

struct IntroView: View {
    @AppStorage("hasShownWelcome") private var hasShownWelcome: Bool = false

    var body: some View {
        IntroPagesView()
    }
}

#Preview {
    IntroView()
}

