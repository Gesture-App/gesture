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
    var arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        // Add bodySkeletonAnchor to scene
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        let configuration = ARBodyTrackingConfiguration()
        configuration.detectionImages = referenceImages
        arView.session.run(configuration, options: [.resetTracking])
        arView.session.delegate = context.coordinator
        arView.debugOptions = [.showAnchorOrigins, .showAnchorGeometry]
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
    static func dismantleUIView(
        _ uiView: Self.UIViewType,
        coordinator: Self.Coordinator
    ) {
        coordinator.timer.invalidate()
        uiView.session.pause()
    }
    
    // Extend ARView to implement body tracking functionality
    class Coordinator: NSObject, ARSessionDelegate {
        var frameCounter: Int = 0
        let handPosePredictionInterval: Int = 12
        
        var parent: ARViewContainer
        
        var timer = Timer()
        private var skeleton: BodySkeleton?
        private var lHandDistance = Queue<Double>(cap: 2)
        private var rHandDistance = Queue<Double>(cap: 2)
        private var lDown = false
        private var rDown = false
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1 / 10, repeats: true, block: { _ in
                self.sendHandData()
            })
        }
        
        private var threshold = 3
        func detect_click(array: [Double], existing: Bool) -> Bool {
            var v = existing
            if array.count >= 3 {
                for i in 0...array.count - 2 {
                    if Int(array[i + 1] / array[i]) > threshold {
                        v = false
                        break
                    } else if Int(array[i] / array[i + 1]) > threshold {
                        v = true
                        break
                    }
                }
            }
            return v
        }
        
        private func sendHandData() {
            if let skeleton = parent.bodySkeleton {
                if skeleton.l_hand.list.count > 0 && skeleton.r_hand.list.count > 0 {
                    // is left click
                    self.lDown = detect_click(array: self.lHandDistance.list, existing: self.lDown)
                    self.rDown = detect_click(array: self.rHandDistance.list, existing: self.rDown)
                    
                    let encode = {(isRight: Bool, entity: Entity) -> HandJSON in
                        let pos = entity.position
                        let clicked = isRight ? self.rDown : self.lDown
                        return HandJSON(x: pos.x, y: pos.y, z: pos.z, shape: clicked ? .closed : .open)
                    }
                    
                    let calc_avg = {(hands: [HandJSON]) -> HandJSON in
                        let x_bar = hands.map({ $0.x }).reduce(0, +) / Float(hands.count)
                        let y_bar = hands.map({ $0.y }).reduce(0, +) / Float(hands.count)
                        let z_bar = hands.map({ $0.z }).reduce(0, +) / Float(hands.count)
                        return HandJSON(x: x_bar, y: y_bar, z: z_bar, shape: hands.first!.shape )
                    }
                    
                    let l = calc_avg(skeleton.l_hand.list.map({(entity: Entity) -> HandJSON in
                        return encode(false, entity)
                    }))
                    let r = calc_avg(skeleton.r_hand.list.map({(entity: Entity) -> HandJSON in
                        return encode(true, entity)
                    }))
                    
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
                        session.setWorldOrigin(relativeTransform: bodyAnchor.transform)
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
                let fingerPoints = try observation.recognizedPoints(.indexFinger)
                
                // Extract individual points from Point groups.
                let thumbTipPoint = thumbPoints[.thumbTip]!
                let fingerPoint = fingerPoints[.indexTip]!
                
                let distance = thumbTipPoint.distance(fingerPoint)
                if thumbTipPoint.confidence > 0.8 && fingerPoint.confidence > 0.8 {
                    if observation.chirality == .left {
                        self.lHandDistance.enqueue(distance)
                    } else if observation.chirality == .right {
                        self.rHandDistance.enqueue(distance)
                    }
                } else {
                    if observation.chirality == .left {
                        self.lHandDistance.enqueue(self.lHandDistance.list.last ?? 0.1)
                    } else if observation.chirality == .right {
                        self.rHandDistance.enqueue(self.rHandDistance.list.last ?? 0.1)
                    }
                }
            } catch {
                // do nothing
                self.lHandDistance.enqueue(self.lHandDistance.list.last ?? 0.1)
                self.rHandDistance.enqueue(self.rHandDistance.list.last ?? 0.1)
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
                handPoseRequest.maximumHandCount = 2

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
                
                if handPoses.count > 1 {
                    makePrediction(observation: handPoses[1])
                }

                frameCounter = 0
            }
            frameCounter += 1
        }
    }
}

