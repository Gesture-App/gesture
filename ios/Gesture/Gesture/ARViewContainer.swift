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

struct Queue<T> {
    public var list = [T]()
    var cap: Int
    
    init(cap: Int) {
        self.cap = cap
    }
    
    mutating func enqueue(_ element: T) {
        if list.count > self.cap {
            // dequeue and throw away res
            let _ = self.dequeue()
        }
        
        list.append(element)
    }

    mutating func dequeue() -> T? {
         if !list.isEmpty {
           return list.removeFirst()
         } else {
           return nil
         }
    }
}

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
        private var handShape = Queue<HandShape>(cap: 3)
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1 / 10, repeats: true, block: { _ in
                self.sendHandData()
            })
        }
        
        func mostFrequent(array: [HandShape]) -> HandShape {
            var counts: [HandShape: Int] = [:]
            array.forEach { counts[$0] = (counts[$0] ?? 0) + 1 }
            if let max_val = counts.max(by: {$0.value < $1.value})?.value {
                return counts.compactMap { $0.value == max_val ? $0.key : nil }.first!
            }
            return .unknown
        }
        
        private func sendHandData() {
            if let skeleton = parent.bodySkeleton {
                if skeleton.l_hand.list.count > 0 && skeleton.r_hand.list.count > 0 {
                    // get most common elt in handshapes
                    let common_shape = mostFrequent(array: self.handShape.list)
                    let _ = print(common_shape.rawValue)
                    let encode = {(entity: Entity) -> HandJSON in
                        let pos = entity.position
                        return HandJSON(x: pos.x, y: pos.y, z: pos.z, shape: common_shape)
                    }
                    
                    let calc_avg = {(hands: [HandJSON]) -> HandJSON in
                        let x_bar = hands.map({ $0.x }).reduce(0, +) / Float(hands.count)
                        let y_bar = hands.map({ $0.y }).reduce(0, +) / Float(hands.count)
                        let z_bar = hands.map({ $0.z }).reduce(0, +) / Float(hands.count)
                        return HandJSON(x: x_bar, y: y_bar, z: z_bar, shape: common_shape)
                    }
                    
                    let l = calc_avg(skeleton.l_hand.list.map(encode))
                    let r = calc_avg(skeleton.r_hand.list.map(encode))
                    
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

        func makePrediction(observation: VNHumanHandPoseObservation) {
            do {
                // Get points for all fingers
                let thumbPoints = try observation.recognizedPoints(.thumb)
                let wristPoints = try observation.recognizedPoints(.all)
                let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
                let middleFingerPoints = try observation.recognizedPoints(.middleFinger)
                let ringFingerPoints = try observation.recognizedPoints(.ringFinger)
                let littleFingerPoints = try observation.recognizedPoints(.littleFinger)
                
                // Extract individual points from Point groups.
                let thumbTipPoint = thumbPoints[.thumbTip]!
                let indexTipPoint = indexFingerPoints[.indexTip]!
                let middleTipPoint = middleFingerPoints[.middleTip]!
                let ringTipPoint = ringFingerPoints[.ringTip]!
                let littleTipPoint = littleFingerPoints[.littleTip]!
                let wristPoint = wristPoints[.wrist]!
                
                let distance = thumbTipPoint.distance(indexTipPoint)
                let _ = print(distance)
                if distance < 0.01 {
                    self.handShape.enqueue(.closed)
                } else {
                    self.handShape.enqueue(.open)
                }
            } catch {
                self.handShape.enqueue(.unknown)
            }

            
//            guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
//            do {
//                // Input to model and execute inference
//                let prediction = try model!.prediction(poses: keypointsMultiArray)
//                let label = prediction.label // The most reliable label
//                guard let confidence = prediction.labelProbabilities[label] else { return }
//                if confidence > 0.8 {
//                    print("label: \(prediction.label) @ confidence:\(confidence)\n")
//                    switch label {
//                    case "closed":
//                        self.handShape = .closed
//                        break
//                    case "open":
//                        self.handShape = .open
//                        break
//                    default:
//                        self.handShape = .unknown
//                    }
//                }
//            } catch {
//                print("Prediction error")
//            }
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
                
                makePrediction(observation: observation)
                frameCounter = 0
            }
            frameCounter += 1
        }
    }
}

