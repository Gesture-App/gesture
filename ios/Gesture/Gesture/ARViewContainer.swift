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
        let _ = print("is this working??!!!")
        
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
        var frameCounter: Int = 0
        let handPosePredictionInterval: Int = 12
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
        
        func displayClosedEffect() {
            let _ = print ("closed")
        }
        
        func displayOpenEffect() {
            let _ = print ("open")
        }
        
        func makePrediction(handPoseObservation: VNHumanHandPoseObservation) {
            // Convert hand point detection results to a multidimensional array
            guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
            do {
                // Input to model and execute inference
                let prediction = try model!.prediction(poses: keypointsMultiArray)
                let label = prediction.label // The most reliable label
                guard let confidence = prediction.labelProbabilities[label] else { return }
                print("label:\(prediction.label)\nconfidence:\(confidence)")
                
                if confidence > 0.9 { // Run with a reliability of 90% or higher
                    switch label {
                    case "closed":displayClosedEffect()
                    case "open":displayOpenEffect()
                    default : break
                    }
                }
            } catch {
                print("Prediction error")
            }
        }
        
        
        
        // Implement ARSession didUpdate anchors delegate method
        public func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // If you execute inference of the model every frame, the processing becomes heavy and it may block the rendering of AR, so inference is executed at intervals.
            if frameCounter % handPosePredictionInterval == 0 {
                // This time we will get the camera frame from ARSession
                let pixelBuffer = frame.capturedImage
                // Create a hand pose detection request
                let handPoseRequest = VNDetectHumanHandPoseRequest()
                // Number of hands to get
                handPoseRequest.maximumHandCount = 1

                // Execute a detection request on the camera frame
                // The frame acquired from the camera is rotated 90 degrees, and if you infer it as it is, the pose may not be recognized correctly, so check the orientation.
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
                do {
                    try handler.perform([handPoseRequest])
                } catch {
                    assertionFailure("HandPoseRequest failed: \(error)")
                }

                guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
                    return
                }

                // Obtained hand data
                guard let observation = handPoses.first else { return }
                
                makePrediction(handPoseObservation: observation)
                frameCounter = 0
            }
            frameCounter += 1
        }
    }
}

