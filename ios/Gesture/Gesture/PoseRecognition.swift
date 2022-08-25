//
//  PoseRecognition.swift
//  Gesture
//
//  Created by Anson Yu on 8/23/22.
//

import CoreML
import Vision

let model = try? Gesture_sm(configuration: MLModelConfiguration())
