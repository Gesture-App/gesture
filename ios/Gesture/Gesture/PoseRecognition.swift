//
//  PoseRecognition.swift
//  Gesture
//
//  Created by Anson Yu on 8/23/22.
//

import CoreML
import Vision

let model = try? GestureModel(configuration: MLModelConfiguration())
