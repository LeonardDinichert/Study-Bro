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
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        ZStack {
                            VStack(spacing: 16) {
//                                Image(systemName: page.systemImage)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 120, height: 120)
//                                    .padding()

                                Text(page.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                

                                Text(page.description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                        }
                        .glassEffect()
                        .shadow(radius: 10)
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())

                Button {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasShownWelcome = true
                    }
                } label: {
                    Text("Continue")
                        .foregroundStyle(.primary)
                        .padding()
                }
                .glassEffect()
                .padding()
            }
        }
    }
}

#Preview {
    IntroPagesView()
}
