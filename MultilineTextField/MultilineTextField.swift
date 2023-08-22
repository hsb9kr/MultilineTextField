//
//  MultilineTextField.swift
//  MultilineTextField
//
//  Created by Red on 2023/08/22.
//

import SwiftUI
import Combine
import SwiftUIIntrospect

struct MultilineTextField: View {
    
    private let regularFontSize: CGFloat
    private let mediumFontSize: CGFloat
    private let backgroundColor: Color = Color(uiColor: UIColor.systemBackground)
    private let padding: CGFloat = 4
    private let minHeight: CGFloat?
    @ObservedObject var viewModel: MultilineTextFieldViewModel
    @State private var bold: Bool?
    @State private var fontSize: CGFloat?
    
    init(regularFontSize: CGFloat = 14, mediumFontSize: CGFloat = 16, minHeight: CGFloat? = 50, onChanged: @escaping ([MultilinTextData]) -> Void) {
        self.regularFontSize = regularFontSize
        self.mediumFontSize = mediumFontSize
        self.minHeight = minHeight
        viewModel = .init(font: regularFontSize, onChanged: onChanged)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<viewModel.viewModels.count, id: \.self) { index in
                let viewModel = viewModel.viewModels[index]
                ItemView(viewModel: viewModel)
            }
            Rectangle()
                .foregroundColor(Color.black.opacity(0.01))
                .frame(minHeight: minHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    guard let last = viewModel.viewModels.last, !last.text.isEmpty else {
                        viewModel.viewModels.last?.focused = true
                        return
                    }
                    let itemViewModel: MultilineTextFieldItemViewModel = .init(font: regularFontSize, onRemove: { viewModel in
                        self.viewModel.onRemove(viewModel: viewModel)
                    })
                    viewModel.viewModels.append(itemViewModel)
                    itemViewModel.focused = true
                }
        }
        .padding()
        .onReceive(viewModel.$focused) { focused in
            bold = focused?.bold
            fontSize = focused?.fontSize
        }
        .environmentObject(viewModel)
        .toolbar(id: "editingTools") {
            ToolbarItem(id: "bold", placement: .keyboard) {
                Button {
                    viewModel.focused?.bold.toggle()
                    bold = viewModel.focused?.bold
                } label: {
                    Image(systemName: "bold")
                        .padding(padding)
                        .background(bold == true ? backgroundColor.cornerRadius(4) : nil)
                }
            }
            ToolbarItem(id: "regular", placement: .keyboard) {
                Button {
                    viewModel.focused?.fontSize = regularFontSize
                    fontSize = viewModel.focused?.fontSize
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .padding(padding)
                        .background(fontSize == regularFontSize ? backgroundColor.cornerRadius(4) : nil)
                }
            }

            ToolbarItem(id: "medium", placement: .keyboard) {
                Button {
                    viewModel.focused?.fontSize = mediumFontSize
                    fontSize = viewModel.focused?.fontSize
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .padding(padding)
                        .background(fontSize == mediumFontSize ? backgroundColor.cornerRadius(4) : nil)
                }
            }
            ToolbarItem(id: "space", placement: .keyboard) {
                Spacer()
            }
        }
        .onAppear {
            UITextView.appearance().backgroundColor = .clear
        }
        .onDisappear {
            UITextView.appearance().backgroundColor = nil
        }
    }
    
    struct ItemView: View {
        
        @EnvironmentObject var parentViewModel: MultilineTextFieldViewModel
        @ObservedObject var viewModel: MultilineTextFieldItemViewModel
        @FocusState private var focused: Bool
        @State var height: CGFloat = 0
        
        var body: some View {
            if #available(iOS 16.0, *) {
                TextField("", text: $viewModel.text, axis: .vertical)
                    .introspect(.textEditor, on: .iOS(.v16)) { view in
                        view.delegate = viewModel
                    }
                    .font(viewModel.displayFont)
                    .focused($focused)
                    .onChange(of: focused) { focused in
                        viewModel.focused = focused
                        if focused {
                            parentViewModel.focused = viewModel
                        }
                    }
                    .onReceive(viewModel.$focused) { value in
                        if value && value != focused {
                            focused = true
                        }
                    }
            } else {
                TextEditor(text: $viewModel.text)
                    .introspect(.textEditor, on: .iOS(.v15)) { view in
                        view.delegate = viewModel
                        view.isScrollEnabled = false
                        view.textContainer.lineFragmentPadding = 0
                        view.textContainerInset = .zero
                        view.contentInset = .zero
                        viewModel.textView = view
                    }
                    .frame(height: viewModel.height)
                    .font(viewModel.displayFont)
                    .focused($focused)
                    .onChange(of: focused) { focused in
                        viewModel.focused = focused
                        if focused {
                            parentViewModel.focused = viewModel
                        }
                    }
                    .onReceive(viewModel.$focused) { value in
                        if value && value != focused {
                            focused = true
                        }
                    }
            }
        }
    }
}

struct MultilineTextField_Previews: PreviewProvider {
    static var previews: some View {
        MultilineTextField() { data in
            
        }
    }
}
