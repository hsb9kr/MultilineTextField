//
//  MultilineTextFieldItemViewModel.swift
//  MultilineTextField
//
//  Created by Red on 2023/08/22.
//

import SwiftUI

class MultilineTextFieldItemViewModel: NSObject, ObservableObject {
    
    private let onRemove: (MultilineTextFieldItemViewModel) -> Void
    @Published var text: String = ""
    @Published var bold = false
    @Published var fontSize: CGFloat
    @Published var focused: Bool = false
    @Published var height: CGFloat = 17
    var data: MultilinTextData {
        .init(bold: bold, fontSize: fontSize, text: text)
    }
    
    var displayFont: Font {
        let font = Font.system(
           size: CGFloat(fontSize),
             weight: bold == true ? .bold : .regular)
        return font
    }
    
    init(font size: CGFloat, onRemove: @escaping (MultilineTextFieldItemViewModel) -> Void) {
        self.onRemove = onRemove
        self.fontSize = size
        super.init()
    }
}

extension MultilineTextFieldItemViewModel: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard textView.text.isEmpty, let char = text.cString(using: String.Encoding.utf8) else {
            return true
        }
        let isBackSpace = strcmp(char, "\\b")
        if (isBackSpace == -92) {
            onRemove(self)
        }
        return true
    }
    
    func sizeToFit(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        if height != newSize.height {
            height = newSize.height
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
        sizeToFit(textView: textView)
        debugPrint("textViewDidChange height: \(height)")
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        sizeToFit(textView: textView)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        sizeToFit(textView: textView)
        return true
    }
}
