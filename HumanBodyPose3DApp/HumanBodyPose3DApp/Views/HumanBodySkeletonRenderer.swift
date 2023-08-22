/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides methods to draw SceneKit nodes from VNHumanBodyPose3DObservation to use in the scene of SkeletonSceneView.
*/

import Foundation
import SceneKit
import Vision
import UIKit
import CoreGraphics

// Creates SceneKit nodes from VNHumanBodyPose3DObservation.
class HumanBodySkeletonRenderer: NSObject {

    public var nodeJointDict: [VNHumanBodyPose3DObservation.JointName: SCNNode] = [:]
    public var imageNodeSize = CGSize(width: 1.8, height: 1.8)
    public var inputImageAlpa: CGFloat = 0.85
    public var cameraNodeAlpa: CGFloat = 0.6
//    public var cameraPyramidGeometry = SCNPyramid(width: 0.25, height: 0.25, length: 0.25)

    // MARK: - The input image plane node.
    // Get the distance between two known joints in 3D, see what proportion of the 2D image they cover, and
    // increase the size of the plane as necessary. Then shift after this is done, and
    // ensure that the image node side is correct.
    func relate3DSkeletonProportionToImagePlane(observation: VNHumanBodyPose3DObservation) -> Float {

        var returnScale: Float = 1.0

        guard
            let centerShoulderNode = self.nodeJointDict[.centerShoulder],
            let spineNode = self.nodeJointDict[.spine]
        else {
            return returnScale
        }

        let distance3D = simd_distance(
            simd_float2(
                x: Float(centerShoulderNode.simdPosition.x) / Float(self.imageNodeSize.width),
                y: Float(centerShoulderNode.simdPosition.y) / Float(self.imageNodeSize.height)
            ),
            simd_float2(
                x: Float(spineNode.simdPosition.x) / Float(self.imageNodeSize.width),
                y: Float(spineNode.simdPosition.y) / Float(self.imageNodeSize.height)
            )
        )

        do {
            let pointCenterShoulder2D = try observation.pointInImage(.centerShoulder)
            let pointSpine2D = try observation.pointInImage(.spine)
            let distance = simd_distance(
                simd_float2(
                    x: Float(pointCenterShoulder2D.x),
                    y: Float(pointCenterShoulder2D.y)
                ),
                simd_float2(
                    x: Float(pointSpine2D.x),
                    y: Float(pointSpine2D.y)
                )
            )
            returnScale = Float(distance3D / distance)
        } catch {
            print("Unable to return point: \(error).")
        }
        return returnScale
    }

    // Use the pointInImage API to determine the translation of the root joint.
    func computeOffsetOfRoot(observation: VNHumanBodyPose3DObservation) -> CGPoint {
        var returnPoint = CGPoint(x: 0, y: 0) // This point will represent the offset of the root joint.
        do {
            let point = try observation.pointInImage(.root)
            // Change to image scale.
            var xShift = Double(point.x * imageNodeSize.width)
            // Recenter origin - translation shift left.
            xShift -= imageNodeSize.width / 2
            // Change to image scale.
            var yShift = Double(point.y * imageNodeSize.height)
            // Recenter origin - translation shift down.
            yShift -= imageNodeSize.height / 2
            returnPoint = CGPoint(x: Double(xShift), y: Double(yShift))
        } catch {
            print("Unable to return point: \(error).")
        }
        return returnPoint
    }

    // Draw the 2D image plane into the scene.
    func createInputImage2DNode(image: UIImage?) -> SCNNode {
        // The SceneKit nodes.
        let imageProjectionNode = SCNNode(
            geometry: SCNPlane(
                width: imageNodeSize.width,
                height: imageNodeSize.height
            )
        )
        imageProjectionNode.position = SCNVector3(0, 0, 0)

        if let inputImage = image {
            let orientedImage = inputImage//imageWithExifOrientationApplied(inputImage) // func is to check the correct orientation of the input image
            imageProjectionNode.geometry?.firstMaterial?.diffuse.contents = orientedImage // to define the visual content of the input image
        }
        imageProjectionNode.opacity = inputImageAlpa // represents the transparency (alpha value) of the image projection node.
        return imageProjectionNode //Finally, the function returns the created imageProjectionNode, which can be added to the SceneKit scene to display the 2D image in a 3D environment.
    }

    // Apply the exif orientation to the image before setting as the material's contents
    func imageWithExifOrientationApplied(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(image.size) //This line starts a new image context with the size of the input image. An image context is like a canvas where you can draw or modify images.
        image.draw(at: .zero) //  It effectively copies the input image onto the image context.
        let orientedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext() // This line ends the current image context and releases any resources associated with it.
        return orientedImage ?? image
    }
    
    // Create the 2D image plane at an appropriate size in meters for the scene.
    func createInputImage2DNode(image: UIImage?, observation: VNHumanBodyPose3DObservation) -> SCNNode {
        if let image = image {
            // Adjust the size of the plane based on the aspect ratio from the default height.
            let aspectRatioW = image.size.width / image.size.height
            self.imageNodeSize.height = self.imageNodeSize.height
            self.imageNodeSize.width = self.imageNodeSize.height * aspectRatioW

            // Create the image node at (0 0 0).
            let imageNode = createInputImage2DNode(image: image) //It essentially creates a plane with the image projected onto it.

            // The rotation needs to match the camera rotation.
            var corrected = observation.cameraOriginMatrix
            corrected.columns.3 = simd_float4(0, 0, 0, 1)
            imageNode.simdTransform = corrected.inverse // This step ensures that the image node's orientation matches the camera's orientation, so the projected image appears correctly aligned with the scene.
            return imageNode
        }
        return createInputImage2DNode(image: nil)
    }

    // MARK: - Camera nodes
    // The purpose of this function is to create and return a 3D representation (a pyramid) of the camera's position in the scene based on the observation data.
//    func createCameraPyramidNode(observation: VNHumanBodyPose3DObservation) -> SCNNode {
//        var originCameraNode = SCNNode()
//        originCameraNode = createNodeForRecognizedPoint(
//            point3D: simd_float3(x: 0, y: 0, z: 0),
//            jointGeometry: cameraPyramidGeometry
//        )
//        originCameraNode.opacity = cameraNodeAlpa
//        originCameraNode.geometry?.firstMaterial?.diffuse.contents = UIColor(.cyan)
//        originCameraNode.simdPivot = cameraRepresentationPivotTransform(observation: observation)
//        return originCameraNode
//    }

    //The purpose of this function is to compute a transformation matrix that adjusts the pivot (center of rotation) of the camera representation, which is typically a pyramid, to align it correctly in the scene.
    func cameraRepresentationPivotTransform(observation: VNHumanBodyPose3DObservation) -> simd_float4x4 {
        // Rotate back 90 degrees because the default position of the pyramid is facing down.
        let rotX90: simd_float4x4 = simd_float4x4(rotationX: -Float.pi / 2)
        return simd_mul(rotX90, observation.cameraOriginMatrix)
    }

    func createCameraNode(observation: VNHumanBodyPose3DObservation) -> SCNNode {
        // Set the default camera to this view.
        let camera = SCNCamera() //This line creates an instance of SCNCamera. The SCNCamera class represents the properties and attributes of a camera in a 3D scene.
        let cameraNode = SCNNode() // This line creates a new, empty SCNNode to serve as the parent node for the camera. A parent node is a container for other nodes, and in this case, the camera node will be attached to this parent node.
        cameraNode.camera = camera
        cameraNode.simdPivot = observation.cameraOriginMatrix
        return cameraNode // This line returns the created cameraNode, which represents the camera node in the 3D scene. The camera node is now attached to an SCNCamera and has its pivot set based on the observation, allowing it to be positioned correctly in the scene.
    }

    // MARK: - Skeleton nodes
    // Creates SceneKit nodes from the points in the observation.
    func createSkeletonNodes(
        observation: VNHumanBodyPose3DObservation
    ) -> [VNHumanBodyPose3DObservation.JointName: SCNNode] {

        var nodeJointDict = [VNHumanBodyPose3DObservation.JointName: SCNNode]() // This dictionary will store the skeleton joints and their corresponding SCNNode representations.
        let skeletonJoints = observation.availableJointNames
//        print("Available Joint Name: ", skeletonJoints)
        for jointName in skeletonJoints {
            do {
                let recognizedPoint = try observation.recognizedPoint(jointName)
                let pointFloat3 = recognizedPoint.position.translationVector // extracts the 3D position of the recognized point
                
                let node = createNodeForRecognizedPoint(
                    point3D: pointFloat3,
                    jointGeometry: defaultNodeGeometry()
                )
                nodeJointDict.updateValue(node, forKey: jointName) //adds the newly created node to the nodeJointDict dictionary with the jointName as the key.
            } catch {
                print("Unable to return point: \(error).")
            }
        }
        self.nodeJointDict = nodeJointDict
        return nodeJointDict
    }

    // Create SceneKit nodes for the recognized points.
    private func createNodeForRecognizedPoint(
        point3D: simd_float3,
        jointGeometry: SCNGeometry
    ) -> SCNNode {
        // The joint node.
        let jointNode = SCNNode(geometry: jointGeometry)
        jointNode.simdPosition = simd_float3(
            x: point3D.x,
            y: point3D.y,
            z: point3D.z
        )
        return jointNode
    }

    // The default keypoint geometry.
    private func defaultNodeGeometry() -> SCNGeometry {
        return SCNBox(
            width: 0.05,
            height: 0.05,
            length: 0.05,
            chamferRadius: 0.05
        )
    }
}

// MARK: - Utilities for the rotation of simd_float4x4.
extension simd_float4x4 {

    public init(rotationX angle: Float) {
        let matrix = float4x4(
            [1, 0, 0, 0],
            [0, cos(angle), sin(angle), 0],
            [0, -sin(angle), cos(angle), 0],
            [0, 0, 0, 1]
        )
        self = matrix
    }

    public init(rotationY angle: Float) {
        let matrix = float4x4(
            [cos(angle), 0, -sin(angle), 0],
            [0, 1, 0, 0],
            [sin(angle), 0, cos(angle), 0],
            [0, 0, 0, 1]
        )
        self = matrix
    }

    public init(rotationZ angle: Float) {
        let matrix = float4x4(
            [ cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        self = matrix
    }
    
    var translationVector: simd_float3 {
        simd_make_float3(
            columns.3[0],
            columns.3[1],
            columns.3[2])
    }
}
