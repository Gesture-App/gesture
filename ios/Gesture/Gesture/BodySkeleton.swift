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
    
    var l_hand: [Entity] = []
    var r_hand: [Entity] = []
    
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            // Default values for joint appearance
            var jointRadius: Float = 0.05
            var jointColor = UIColor.green
            
            // Set color and size based on specific jointName
            // NOTE: Green joints are actively tracked by ARKit. Yellow joints are not tracked. They just follow the motion of the closest green parent.
            switch jointName {
            case "neck_1_joint", "neck_2_joint", "neck_3_joint", "neck_4_joint", "head_joint", "left_shoulder_1_joint", "right_shoulder_1_joint":
                jointRadius *= 0.5
            case "jaw_joint", "chin_joint", "left_eye_joint", "left_eyeLowerLid_joint", "left_eyeUpperLid_joint", "left_eyeball_joint", "nose_joint", "right_eye_joint", "right_eyeLowerLid_joint", "right_eyeUpperLid_joint", "right_eyeball_joint":
                jointRadius *= 0.2
                jointColor = .black
            case _ where jointName.hasPrefix("spine_"):
                jointRadius *= 0.75
            case "left_hand_joint", "right_hand_joint":
                jointRadius *= 1
                jointColor = .white
            case _ where jointName.hasPrefix("left_hand"):
                jointRadius *= 0.25
                jointColor = .red
            case _ where jointName.hasPrefix("right_hand"):
                jointRadius *= 0.25
                jointColor = .blue
            case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
                jointRadius *= 0.5
                jointColor = .black
            default:
                jointRadius = 0.05
                jointColor = .white
            }
            
            // Create an entity for the joint, add to joints directory, and add it to the parent entity (i.e. bodySkeleton)
            let jointEntity = createJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        for bone in Bones.allCases {
            guard let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            // Create an entity for the bone, add to bones directory, and add it to the parent entity (i.e. bodySkeleton)
            let boneEntity = createBoneEntity(for: skeletonBone)
            bones[bone.name] = boneEntity
            self.addChild(boneEntity)
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
        
        self.l_hand.append(l!)
        self.r_hand.append(r!)
        
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
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
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
    
    private func createBoneEntity(for skeletonBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletonBone.length], cornerRadius: diameter/2)
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        return entity
    }
}
