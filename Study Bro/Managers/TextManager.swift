//
//  TextManager.swift
//  Jobb
//
//  Created by Léonard Dinichert on 13.11.2024.
//
import SwiftUI
import UIKit

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType
        
        // Disable the input assistant view
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}


struct GrowingTextEditor: UIViewRepresentable {
    @Binding var text: String
    var minHeight: CGFloat = 28
    var maxHeight: CGFloat = 100

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextEditor
        
        init(parent: GrowingTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            
            // Scroll to the end so the new text is visible.
            // Ensure we have at least one character.
            if textView.text.count > 0 {
                let location = textView.text.count - 1
                let range = NSMakeRange(location, 1)
                textView.scrollRangeToVisible(range)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true  // Allow scrolling when content is large.
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.text = text
        // Disable autocorrection and autocapitalization if desired:
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}
