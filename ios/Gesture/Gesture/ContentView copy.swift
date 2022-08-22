//
//  ContentView.swift
//  Gesture
//
//  Created by Jacky Zhao on 2022-08-22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
        Text("Hello, world!")
            .padding()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
