//
//  ShowPasswordView.swift
//  Study Bro
//
//  Created by Léonard Dinichert
//

import SwiftUI

struct ShowPasswordView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Modify my password")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.leading)
            
            NavigationLink {
                ResetPasswordView()
            } label: {
                Text("Reset my password")
            }
            .buttonStyle(.borderedProminent)
            .padding(.leading)
            Spacer()
        }
    }
}

struct ShowPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ShowPasswordView()
    }
}
