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
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        ZStack {
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

#Preview {
    IntroPagesView()
}
