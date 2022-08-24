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

// Wraps UIKit-based ARView to be used in SwiftUI View
struct ARViewContainer: UIViewRepresentable  {
    var bluetooth = BluetoothManager()
    var bodySkeleton: BodySkeleton?
    let bodySkeletonAnchor = AnchorEntity()
    
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
    
    static func dismantleUIView(
        _ uiView: Self.UIViewType,
        coordinator: Self.Coordinator
    ) {
    }
    
    // Extend ARView to implement body tracking functionality
    class Coordinator: NSObject, ARSessionDelegate {
        var frameCounter: Int = 0
        let handPosePredictionInterval: Int = 12
        
        var parent: ARViewContainer
        
        private var timer = Timer()
        private var skeleton: BodySkeleton?
        private var handShape: HandShape = .unknown
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1 / 10, repeats: true, block: { _ in
                self.sendHandData()
            })
        }
        
        private func sendHandData() {
            if let skeleton = parent.bodySkeleton {
                if skeleton.l_hand.count > 0 && skeleton.r_hand.count > 0 {
                    let encode = {(entity: Entity) -> HandJSON in
                        let pos = entity.position
                        return HandJSON(x: pos.x, y: pos.y, z: pos.z, shape: self.handShape)
                    }
                    
                    let calc_avg = {(hands: [HandJSON]) -> HandJSON in
                        let x_bar = hands.map({ $0.x }).reduce(0, +) / Float(hands.count)
                        let y_bar = hands.map({ $0.y }).reduce(0, +) / Float(hands.count)
                        let z_bar = hands.map({ $0.z }).reduce(0, +) / Float(hands.count)
                        return HandJSON(x: x_bar, y: y_bar, z: z_bar, shape: self.handShape)
                    }
                    
                    let l = calc_avg(skeleton.l_hand.map(encode))
                    let r = calc_avg(skeleton.r_hand.map(encode))
                    
                    do {
                        let payload: Payload = Payload(left: l, right: r)
                        let jsonData = try JSONEncoder().encode(payload)
                        let data = Data.init(jsonData)
                        parent.bluetooth.peripheralManager.updateValue(
                            data,
                            for: parent.bluetooth.handsCharacteristic,
                            onSubscribedCentrals: [
                                parent.bluetooth.pairedTo!
                            ]
                        )
                        
                        // reset l and r
                        parent.bodySkeleton!.l_hand = []
                        parent.bodySkeleton!.r_hand = []
                    } catch { {}() }
                }
            }
        }
        
        // Implement ARSession didUpdate anchors delegate method
        public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    
                    // Create or update bodySkeleton
                    if let skeleton = parent.bodySkeleton {
                        // BodySkeleton already exists, update pose of all joints
                        skeleton.update(with: bodyAnchor)
                    } else {
                        parent.bodySkeleton = BodySkeleton(for: bodyAnchor)
                        parent.bodySkeletonAnchor.addChild(parent.bodySkeleton!)
                    }
                }
            }
        }

        func makePrediction(handPoseObservation: VNHumanHandPoseObservation) {
            // Convert hand point detection results to a multidimensional array
            guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
            do {
                // Input to model and execute inference
                let prediction = try model!.prediction(poses: keypointsMultiArray)
                let label = prediction.label // The most reliable label
                guard let confidence = prediction.labelProbabilities[label] else { return }
                if confidence > 0.8 {
                    print("label: \(prediction.label) @ confidence:\(confidence)\n")
                    switch label {
                    case "closed":
                        self.handShape = .closed
                        break
                    case "open":
                        self.handShape = .open
                        break
                    default:
                        self.handShape = .unknown
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

