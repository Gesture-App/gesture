//
//  ARViewContainer.swift
//  Gesture
//
//  Created by Anson Yu on 8/22/22.
//

import SwiftUI
import RealityKit
import ARKit
import CoreBluetooth

private var bodySkeleton: BodySkeleton?
private var receiver: CBCentral?
private let bodySkeletonAnchor = AnchorEntity()

// Wraps UIKit-based ARView to be used in SwiftUI View
struct ARViewContainer: UIViewRepresentable  {
    var bluetooth = BluetoothManager()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        // Add bodySkeletonAnchor to scene
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
    // Extend ARView to implement body tracking functionality
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        // Implement ARSession didUpdate anchors delegate method
        public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    // Create or update bodySkeleton
                    if let skeleton = bodySkeleton {
                        // BodySkeleton already exists, update pose of all joints
                        skeleton.update(with: bodyAnchor)
                    } else {
                        bodySkeleton = BodySkeleton(for: bodyAnchor, bluetooth: parent.bluetooth)
                        bodySkeletonAnchor.addChild(bodySkeleton!)
                    }
                }
            }
        }
    }
}

