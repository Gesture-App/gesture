//
//  BodySkeleton.swift
//  Gesture
//
//  Created by Anson Yu on 8/22/22.
//

import Foundation
import RealityKit
import ARKit

class BodySkeleton: Entity {
    
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    required init(for bodyAnchor: ARBodyAnchor){
        super.init()
    }
    
    required init(){
        fatalError("init() has not been implemented")
    }
    
    private func createJoint(radius: Float, color: UIColor) -> Entity {
        let mesh = MeshResource.generateSphere(radius:radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials:[material])
        return entity
    }
    
    private func createSkeletonBone(bone:Bones, bodyAnchor:ARBodyAnchor) -> SkeletonBone? {
        guard let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)),
              let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName))
        else { return nil }
        
        // Position relative to the hip joint
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        // Relative to hip joint for FROM
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3)
        
        // Relative to world reference for FROM
        let jointFromEntityPosition = jointFromEntityOffsetFromRoot + rootPosition
        
        // Relative to hip joint for TO
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3)
        
        // Relative to world reference for TO
        let jointToEntityPosition = jointToEntityOffsetFromRoot + rootPosition
        
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromEntityPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToEntityPosition)
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
    
}
