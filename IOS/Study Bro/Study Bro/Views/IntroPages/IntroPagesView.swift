//
//  IntroPagesView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI

struct IntroPagesView: View {
    let pages = IntroPagesModel.pages
    
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                LinearGradient(colors: pages[currentPage].gradient,
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .opacity(0.65)
                .ignoresSafeArea()
                .animation(.easeInOut, value: currentPage)
                
                VStack {
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { index in
                            VStack(spacing: 24) {
                                Image(systemName: pages[index].systemImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .padding()
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        LinearGradient(colors: pages[index].gradient,
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                
                                VStack(spacing: 16) {
                                    Text(pages[index].title)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Text(pages[index].description)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    
                    if currentPage == pages.count - 1 {
                        NavigationLink("Continue") {
                            LegalConditions()
                        }
                        .padding()
                        .font(.headline)
                    }
                }
            }
        }
        
    }
}

#Preview {
    IntroPagesView()
}
