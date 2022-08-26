//
//  BodySkeleton.swift
//  Gesture
//
//  Created by Anson Yu on 8/22/22.
//

import Foundation
import RealityKit
import ARKit

enum HandShape: String, Codable {
    case open
    case closed
    case unknown
}

struct HandJSON: Codable {
    let x: Float
    let y: Float
    let z: Float
    let shape: HandShape
}

struct Payload: Codable {
    let left: HandJSON
    let right: HandJSON
}

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    
    var l_hand = Queue<Entity>(cap: 10)
    var r_hand = Queue<Entity>(cap: 10)
    
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            // Default values for joint appearance
            var jointRadius: Float = 0.05
            var jointColor = UIColor.green
            var toRender = false
            
            switch jointName {
            case "left_hand_joint":
                jointRadius *= 1
                jointColor = .blue
                toRender = true
                break
            case "right_hand_joint":
                jointRadius *= 1
                jointColor = .red
                toRender = true
            default:
                break
            }
            
            if toRender {
                // Create an entity for the joint, add to joints directory, and add it to the parent entity (i.e. bodySkeleton)
                let jointEntity = createJoint(radius: jointRadius, color: jointColor)
                toRender = true
                joints[jointName] = jointEntity
                self.addChild(jointEntity)
            }
        }
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    func update(with bodyAnchor: ARBodyAnchor) {
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        var l: Entity?
        var r: Entity?
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName], let jointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                
                let jointEntityOffsetFromRoot = simd_make_float3(jointEntityTransform.columns.3) // relative to root (i.e. hipJoint)
                jointEntity.position = jointEntityOffsetFromRoot + rootPosition // relative to world reference frame
                
                jointEntity.orientation = Transform(matrix: jointEntityTransform).rotation
                if jointName == "left_hand_joint" {
                    l = jointEntity
                } else if jointName == "right_hand_joint" {
                    r = jointEntity
                }
            }
        }
        
        self.l_hand.enqueue(l!)
        self.r_hand.enqueue(r!)
        
        for bone in Bones.allCases {
            let boneName = bone.name
            
            guard let entity = bones[boneName],
                  let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            entity.position = skeletonBone.centerPosition
            entity.look(at: skeletonBone.toJoint.position, from: skeletonBone.centerPosition, relativeTo: nil) // Sets orientation for bone
        }
    }
    
    private func createJoint(radius: Float, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 1, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    // NOTE: a SkeletonBone is not yet an entity that can be visualized. It is simply an object that contains the parameters needed to visualize a bone entity.
    private func createSkeletonBone(bone: Bones, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)),
              let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName))
        else { return nil }
        
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        // Relative to hip joint for FROM
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3)
        
        // Relative to world reference for FROM
        let jointFromEntityPosition = jointFromEntityOffsetFromRoot + rootPosition
        
        // Relative to hip joint for TO
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3) // relative to root (i.e. hipJoint)
        let jointToEntityPosition = jointToEntityOffsetFromRoot + rootPosition // relative to world reference frame
        
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromEntityPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToEntityPosition)
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
}
