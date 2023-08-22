//
//  MultilineTextField.swift
//  MultilineTextField
//
//  Created by Red on 2023/08/22.
//

import SwiftUI
import Combine

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
                    let itemViewModel: MultilineTextFieldItemViewModel = .init(font: regularFontSize)
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
    }
    
    struct ItemView: View {
        
        @EnvironmentObject var parentViewModel: MultilineTextFieldViewModel
        @ObservedObject var viewModel: MultilineTextFieldItemViewModel
        @FocusState private var focused: Bool
        
        var body: some View {
            TextField("", text: $viewModel.text, axis: .vertical)
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

class MultilineTextFieldItemViewModel: ObservableObject {
    
    @Published var text: String = ""
    @Published var bold = false
    @Published var fontSize: CGFloat
    @Published var focused: Bool = false
    var data: MultilinTextData {
        .init(bold: bold, fontSize: fontSize, text: text)
    }
    
    var displayFont: Font {
        let font = Font.system(
           size: CGFloat(fontSize),
             weight: bold == true ? .bold : .regular)
        return font
    }
    
    init(font size: CGFloat) {
        self.fontSize = size
    }
}

class MultilineTextFieldViewModel: ObservableObject {
    private var cancellables: Set<AnyCancellable> = []
    @Published var viewModels: [MultilineTextFieldItemViewModel]
    @Published var focused: MultilineTextFieldItemViewModel?
    
    init(font size: CGFloat, onChanged: @escaping ([MultilinTextData]) -> Void) {
        viewModels = [.init(font: size)]
        $viewModels
            .flatMap { viewModels in
                let textPublisher = Publishers
                    .MergeMany(viewModels
                        .compactMap { $0.$text })
                        .map { _ in () }
                let boldPublisher = Publishers
                    .MergeMany(viewModels
                        .compactMap { $0.$bold })
                        .map { _ in () }
                let fontSizePublisher = Publishers
                    .MergeMany(viewModels
                        .compactMap { $0.$fontSize })
                        .map { _ in () }
                return Publishers
                    .Merge3(textPublisher, boldPublisher, fontSizePublisher)
                    .dropFirst(3)
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                let data: [MultilinTextData] = self.viewModels.map { $0.data }
                onChanged(data)
            }
            .store(in: &cancellables)
    }
}

struct MultilineTextField_Previews: PreviewProvider {
    static var previews: some View {
        MultilineTextField() { data in
            
        }
    }
}

struct MultilinTextData {
    let bold: Bool
    let fontSize: CGFloat
    let text: String
}
