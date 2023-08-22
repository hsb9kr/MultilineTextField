//
//  ContentView.swift
//  MultilineTextField
//
//  Created by Red on 2023/08/22.
//

import SwiftUI

struct ContentView: View {
    
    @State var text: String = ""
    
    var body: some View {
        ScrollView {
            MultilineTextField() { data in
                debugPrint(data)
            }
        }
//        VStack {
    //        MultilineTextField()
//        }
//        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
