//
//  JobIntroView.swift
//  Study BroStudy Bro
//
//  Created by Léonard Dinichert
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

