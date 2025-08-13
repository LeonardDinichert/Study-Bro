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
            .animation(.easeInOut, value: currentPage)
            
            
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
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        LinearGradient(colors: page.gradient,
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                
                                VStack(spacing: 16) {
                                    
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
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? AnyShapeStyle(LinearGradient(colors: pages[index].gradient,
                                                                                          startPoint: .top,
                                                                                          endPoint: .bottom)) : AnyShapeStyle(Color.white.opacity(0.3)))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 8)
                    
                    Button {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                hasShownWelcome = true
                            }
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
                        .cornerRadius(AppTheme.cornerRadius)
                    )
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .padding()
                    
                    if currentPage < pages.count - 1 {
                        Button {
                            currentPage += 1
                        } label: {
                            Text("Continue")
                                .foregroundStyle(.primary)
                                .padding()
                        }
                    } else {
                        NavigationLink {
                            
                        } label: {
                            Text("Continue")
                                .foregroundStyle(.primary)
                                .padding()
                        }
                    }
                }
                
            }
        }
        
    }
}

#Preview {
    IntroPagesView()
}
