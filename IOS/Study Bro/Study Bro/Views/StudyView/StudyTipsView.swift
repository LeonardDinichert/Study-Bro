import SwiftUI

struct StudyTipsView: View {
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
                let md = try StudyTechniquesLoader.loadLocalizedMarkdown()
                var a = try TermsParser.parse(md)
                TermsStyler.applyBrandTypography(&a)
                TermsStyler.insertLineBreaksBeforeListItems(&a)
                terms = a
            } catch {
                loadError = "Text content is unavailable."
            }
        }
    }
}
