//
//  IntroPagesView.swift
//  SchoolAssisstant
//
//  Created by OpenAI on 2025.
//

import SwiftUI

struct IntroPagesView: View {
    let pages = IntroPagesModel.pages
    
    @AppStorage("hasShownWelcome") private var hasShownWelcome: Bool = false
    
    var body: some View {
        VStack {
            TabView {
                ForEach(pages) { page in
                    VStack(spacing: 16) {
                        Image(systemName: page.systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding()

                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(page.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())

            Button("Continue") {
                hasShownWelcome = true
            }
            .padding()
        }
    }
}

#Preview {
    IntroPagesView()
}

