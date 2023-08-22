/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detector serves as the view model for the scene and interfaces with the Vision framework to run the request and related  calculations.
*/

import Foundation
import Vision
import SceneKit
import AVFoundation
import Photos
import simd
import SwiftUI

@available(iOS 17.0, *)
class HumanBodyPose3DDetector: NSObject, ObservableObject {
    @Published var humanObservation: VNHumanBodyPose3DObservation? = nil
    var fileURL: URL? = URL(string: "")
    @StateObject var frameModel = FrameHandler()
    var cgImage: CGImage?
    

    // MARK: - The angle from the child joint to the parent joint.
    public func calculateLocalAngleToParent(joint: VNHumanBodyPose3DObservation.JointName) -> simd_float3 {
//        print("calculateLocalAngleToParent")
        var angleVector: simd_float3 = simd_float3()
        do {
            if let observation = self.humanObservation {
                let recognizedPoint = try observation.recognizedPoint(joint)
                let childPosition = recognizedPoint.localPosition
                let translationC  = childPosition.translationVector
                // The rotation for x, y, z.
                // Rotate 90 degrees from the default orientation of the node. Add yaw and pitch, and connect the child to the parent.
                let pitch = (Float.pi / 2)
                let yaw = acos(translationC.z / simd_length(translationC))
                let roll = atan2((translationC.y), (translationC.x))
                angleVector = simd_float3(pitch, yaw, roll)
                // print the points
//                print(try observation.pointInImage(joint))
            }
        } catch {
            print("Unable to return point: \(error).")
        }
        return angleVector
    }

    // MARK: - Create and run the request on the asset URL.
    // ML model implementation
    public func runHumanBodyPose3DRequestOnImage(cgImage: CGImage?) async {
//        print("runHumanBodyPose3DRequestOnImage")
        await Task(priority: .userInitiated) {
//            guard let assetURL = fileURL else {
//                return
//            }
            let request = VNDetectHumanBodyPose3DRequest()
//            self.fileURL = fileURL
            if let frame = cgImage{
                let requestHandler = VNImageRequestHandler(cgImage: frame)
                self.cgImage = frame
                do {
                    try requestHandler.perform([request])
                    if let returnedObservation = request.results?.first {
                        Task { @MainActor in
                            self.humanObservation = returnedObservation
                        }
                        //                    print("Returned observations from the ML model: ",returnedObservation.pointInImage(VNHumanBodyPose3DObservation.JointName))
                    }
                    
                } catch {
                    print("Unable to perform the request: \(error).")
                }
            }
            else {
                print("print image is nil")
            }
        }.value
    }
}
