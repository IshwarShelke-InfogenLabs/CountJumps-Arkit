/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 The view that creates the NavigationStack between photo selection views and Skeleton Scene rendering views.
 */

import Foundation
import PhotosUI
import SwiftUI
import Vision

//func requestAuthorization() {
//    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
//    case .notDetermined:
//        PHPhotoLibrary.requestAuthorization(for: .readWrite) { code in
//            if code == .authorized {
//                print("Photos Permissions granted.")
//            }
//        }
//
//    case .restricted, .denied:
//        print("Please allow access to Photos to use the app.")
//    case .authorized:
//        print("Authorized for Photos access.")
//    case .limited:
//        print("Limited Photos access.")
//    @unknown default:
//        print("Unable to access Photos.")
//    }
//}

var jumping = false
var goingDown = false

@available(iOS 17.0, *)
struct PhotoSelectionView: View {
    @StateObject var viewModel = HumanBodyPoseImageModel()
    @StateObject var frameModel = FrameHandler()
    @StateObject var skeletonModel = HumanBodyPose3DDetector()
    @State private var showSkeleton = false
    @State private var buttonPrompt: String = "Show Skeleton"
    @State private var arr:[Double] = []
    @State var jumpCount = 0
    @State private var toggle: Bool = true {
        didSet {
            Task {
                print("Initialise task")
//                frameModel.intializeRequests()
//                FrameHandler.instanse?.frame = frameModel.frame
                await skeletonModel.runHumanBodyPose3DRequestOnImage(cgImage: frameModel.frame)
                
                
                let temp = ""
                guard let observation =  skeletonModel.humanObservation else {
                    return temp
                }
                
                _ = observation.availableJointNames
                
//                let rec_point_root = try? observation.recognizedPoint(.root)
                
//                print("rec_point_root points wrt camera: ", rec_point_root as Any)
//                 gives coordinates of root relative to camera position(apparently considers camera position as origin
                let cameraPosition = try? observation.cameraRelativePosition(.root)
              
                let XRoot = cameraPosition!.columns.3.x
                let YRoot = cameraPosition!.columns.3.y
                let ZRoot = cameraPosition!.columns.3.z
                
                print("X: \(XRoot) | Y: \(YRoot) | Z: \(ZRoot)")
                print("Root ")

                arr.append(Double(YRoot))
                print("Min:  \(String(describing: arr.min())) | Max \(String(describing: arr.max()))")
                
                
                // threshold values
                let thresholdUp: Float = 0.4 //max
                let thresholdDown: Float = -0.4 // min

                if YRoot < thresholdDown && !jumping {
                    goingDown = true
                }
                
                if YRoot > thresholdUp && goingDown {
                    jumping = true
                    jumpCount += 1
                    goingDown = false
                }
                
                if YRoot > thresholdDown {
                    jumping = false // Reset jumping flag
                }
                
                print("JumpCount: ", jumpCount)
                
                return temp
            }
            
        }
    }
    
    
    var body: some View {
        ZStack {
            FrameView(image: frameModel.frame)
                .ignoresSafeArea()
                .onChange(of: frameModel.frame) {
                    toggle = true
                }
            
            SkeletonScene(viewModel: skeletonModel, image: frameModel.frame) // AR
        }
    }

}

