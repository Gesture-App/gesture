//
//  ARViewContainer.swift
//  Gesture
//
//  Created by Anson Yu on 8/22/22.
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer : UIViewRepresentable {
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
     
    }
    
}
