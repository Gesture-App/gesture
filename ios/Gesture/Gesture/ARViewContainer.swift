//
//  ARViewContainer.swift
//  Gesture
//
//  Created by Anson Yu on 8/22/22.
//

import SwiftUI
import RealityKit
import ARKit

private var bodySkeleton: BodySkeleton?
private let bodySkeletonAnchor = AnchorEntity()

// Wraps UIKit-based ARView to be used in SwiftUI View
struct ARViewContainer: UIViewRepresentable {
    typealias UIViewType = ARView
    
    func makeUIView(context: UIViewRepresentableContext<ARViewContainer>) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        arView.setupForBodyTracking()
        
        // Add bodySkeletonAnchor to scene
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: UIViewRepresentableContext<ARViewContainer>) {
        
    }
}

// Extend ARView to implement body tracking functionality
extension ARView: ARSessionDelegate {
    // Configure ARView for body tracking
    func setupForBodyTracking() {
        let configuration = ARBodyTrackingConfiguration()
        self.session.run(configuration)
        
        self.session.delegate = self
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
                    // BodySkeleton doesn't exist yet. This means human body detected for the first time.
                    // Create a bodySkeleton entity and add it to the bodySkeletonAnchor
                    bodySkeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeletonAnchor.addChild(bodySkeleton!)
                }
            }
        }
    }
}
