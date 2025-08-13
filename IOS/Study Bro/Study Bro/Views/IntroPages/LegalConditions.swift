//
//  LegalConditions.swift
//  Study Bro
//
//  Created by Léonard Dinichert on 13.08.2025.
//

import SwiftUI
import Foundation

// MARK: - Load localized Markdown
enum TermsLoader {
    static func loadLocalizedMarkdown() throws -> String {
        let bundle = Bundle.main

        // Try preferred localization, then base, then English as fallback
        let tryOrder: [String?] = [Locale.current.languageCode, nil, "en"]

        for loc in tryOrder {
            if let url = bundle.url(forResource: "terms", withExtension: "md",
                                    subdirectory: nil, localization: loc)
                ?? bundle.url(forResource: "terms", withExtension: "md") {
                do {
                    return try String(contentsOf: url, encoding: .utf8)
                } catch {
                    // Fallback encodings if file isn't UTF-8
                    let data = try Data(contentsOf: url)
                    if let s = String(data: data, encoding: .utf8)
                        ?? String(data: data, encoding: .isoLatin1) {
                        return s
                    }
                    throw error
                }
            }
        }

        throw NSError(domain: "terms", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "terms.md not found in bundle/localizations"])
    }
}

// MARK: - Parse Markdown -> AttributedString
enum TermsParser {
    static func parse(_ markdown: String) throws -> AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        return try AttributedString(markdown: markdown, options: opts, baseURL: nil)
    }
}

// MARK: - Styling: headings + lists + line breaks before items
enum TermsStyler {

    /// Optional: tweak fonts here (system by default; replace with .custom if you have brand fonts)
    static func applyBrandTypography(_ s: inout AttributedString) {
        for run in s.runs {
            guard let intent = run.presentationIntent else { continue }

            for comp in intent.components {
                switch comp.kind {
                case .header(level: let lvl):
                    var c = AttributeContainer()
                    switch lvl {
                    case 1: c.font = .system(size: 34, weight: .bold)
                    case 2: c.font = .system(size: 28, weight: .bold)
                    case 3: c.font = .system(size: 22, weight: .semibold)
                    case 4: c.font = .system(size: 20, weight: .semibold)
                    default: c.font = .system(size: 17, weight: .semibold)
                    }
                    s[run.range].mergeAttributes(c)

                case .unorderedList, .orderedList:
                    var c = AttributeContainer()
                    c.font = .system(size: 17, weight: .regular)
                    s[run.range].mergeAttributes(c)

                default:
                    break
                }
            }
        }
    }

    /// Inserts a single newline before each list item so bullets/numbers start on a new line
    static func insertLineBreaksBeforeListItems(_ s: inout AttributedString) {
        var result = AttributedString()
        var cursor = s.startIndex

        for run in s.runs {
            // copy preceding segment
            if cursor < run.range.lowerBound {
                result.append(s[cursor..<run.range.lowerBound])
            }

            // is this run a list item?
            let isListItem: Bool = {
                guard let intent = run.presentationIntent else { return false }
                return intent.components.contains { if case .listItem = $0.kind { return true } else { return false } }
            }()

            // insert newline before list item if needed
            if isListItem {
                let isEmpty = result.characters.isEmpty
                let lastChar = result.characters.last
                if !isEmpty, let last = lastChar, last != "\n" {
                    result.append(AttributedString("\n"))
                }
            }

            // append the run itself
            result.append(s[run.range])
            cursor = run.range.upperBound
        }

        // append trailing tail
        if cursor < s.endIndex {
            result.append(s[cursor..<s.endIndex])
        }

        s = result
    }
}

struct LegalConditions: View {

    @AppStorage("hasShownWelcome") private var hasShownWelcome: Bool = false
    @State private var hasAcknowledged: Bool = false

    @State private var terms: AttributedString = AttributedString("Loading…")
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("App Usage Conditions")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)

                    Group {
                        if let loadError {
                            Text(loadError)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(terms)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }

                    Toggle(isOn: $hasAcknowledged) {
                        Text("I have read and acknowledge the usage conditions.")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    Button {
                        hasShownWelcome = true
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasAcknowledged ? Color.accentColor : Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.15), value: hasAcknowledged)
                    }
                    .disabled(!hasAcknowledged)
                }
                .padding()
            }
            .task {
                do {
                    let md = try TermsLoader.loadLocalizedMarkdown()
                    var a = try TermsParser.parse(md)
                    TermsStyler.applyBrandTypography(&a)
                    TermsStyler.insertLineBreaksBeforeListItems(&a)
                    terms = a
                } catch {
                    loadError = "Terms unavailable."
                }
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LegalConditions()
}
