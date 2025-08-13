//
//  IntroPagesView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI

struct IntroPagesView: View {
    let pages = IntroPagesModel.pages
    
    @AppStorage("hasShownWelcome") private var hasShownWelcome: Bool = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(colors: pages[currentPage].gradient,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        ZStack {
                            VStack(spacing: 24) {
                                Image(systemName: page.systemImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .padding()
                                    .foregroundStyle(
                                        LinearGradient(colors: page.gradient,
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )

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
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

                Button {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasShownWelcome = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(
                    LinearGradient(colors: pages[currentPage].gradient,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                        .cornerRadius(12)
                )
                .foregroundColor(.white)
                .shadow(radius: 5)
                .padding()
            }
        }
    }
}

#Preview {
    IntroPagesView()
}
