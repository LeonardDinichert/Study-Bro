//
//  LegalView.swift
//  SchoolAssisstant
//
//  Created by Léonard Dinichert on 11.06.2025.
//

import SwiftUI

struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Legal Information")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)

                Group {
                    Text("Terms of Use")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("By using SchoolAssisstant you agree to use the app for personal study only. We do not guarantee the accuracy of provided data and reserve the right to modify the service at any time.")
                }

                Group {
                    Text("Privacy Policy")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Your study sessions and profile details are stored securely in your iCloud account. They are not shared with third parties. You may remove all data by deleting your account.")
                }

                Group {
                    Text("Data Deletion")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Deleting your account permanently removes your notes, study history and any personal information from our servers.")
                }

                Group {
                    Text("Contact")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Questions or concerns? Email support@schoolassistant.app.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Legal")
    }
}

#Preview {
    LegalView()
}
