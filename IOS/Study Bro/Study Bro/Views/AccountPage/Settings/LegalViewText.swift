//
//  LegalViewText.swift
//  Study Bro
//
//  Created by Léonard Dinichert on 14.08.2025.
//

import SwiftUI

struct LegalViewText: View {
    @State private var terms: AttributedString = .init()
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            if let loadError {
                Text(loadError)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                Text(terms)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .task {
            do {
                let md = try TermsLoader.loadLocalizedMarkdown()
                var a = try TermsParser.parse(md)
                TermsStyler.insertLineBreaksBeforeListItems(&a)
                terms = a
            } catch {
                loadError = "Terms unavailable."
            }
        }
    }
}
