//
//  ShowPasswordView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI

struct ShowPasswordView: View {
    var body: some View {
        ZStack {
            // Background gradient for depth
            LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.2), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(spacing: 24) {
                    Image(systemName: "lock.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(Color.accentColor)
                        .shadow(radius: 7)
                        .padding(.top, 16)

                    Text("Modify my password")
                        .font(.title).bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        ResetPasswordView()
                    } label: {
                        Text("Reset my password")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(radius: 12)
                .padding(.horizontal)
                Spacer()
            }
        }
    }
}

struct ShowPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ShowPasswordView()
    }
}
