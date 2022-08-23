//
//  ContentView.swift
//  Gesture_Skeleton
//
//  Created by Anson Yu on 8/22/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
