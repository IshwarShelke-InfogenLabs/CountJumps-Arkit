//  FrameView.swift
//  LiveCamera

import AVFoundation
import CoreImage
import UIKit
import Vision
import MetalKit
import CoreImage.CIFilterBuiltins


//struct AngleColors {
//    
//    let red: CGFloat
//    let blue: CGFloat
//    let green: CGFloat
//    
//    init(roll: NSNumber?, pitch: NSNumber?, yaw: NSNumber?) {
//        red = AngleColors.convert(value: roll, with: -.pi, and: .pi)
//        blue = AngleColors.convert(value: pitch, with: -.pi / 2, and: .pi / 2)
//        green = AngleColors.convert(value: yaw, with: -.pi / 2, and: .pi / 2)
//    }
//    
//    static func convert(value: NSNumber?, with minValue: CGFloat, and maxValue: CGFloat) -> CGFloat {
//        guard let value = value else { return 0 }
//        let maxValue = maxValue * 0.8
//        let minValue = minValue + (maxValue * 0.2)
//        let facePoseRange = maxValue - minValue
//        
//        guard facePoseRange != 0 else { return 0 } // protect from zero division
//        
//        let colorRange: CGFloat = 1
//        return (((CGFloat(truncating: value) - minValue) * colorRange) / facePoseRange)
//    }
//}



class FrameHandler: NSObject, ObservableObject {

    
    @Published var frame: CGImage? {
        didSet {
            if frame == nil {
                print("print frame is nil")
            }
        }
    }
    private var permissionGranted = true
    // The capture session that provides video frames.
    public var session: AVCaptureSession?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    private var frameRate = 0
    public var currentCIImage: CIImage?
    // The Vision requests and the handler to perform them.
    private let requestHandler = VNSequenceRequestHandler()
    private var facePoseRequest: VNDetectFaceRectanglesRequest!
    private var segmentationRequest = VNGeneratePersonSegmentationRequest()
//    
//    // A structure that contains RGB color intensity values.
//    private var colors: AngleColors?
//    static var instanse : FrameHandler? {
//        didSet {
//            print("print CameraFrame instanse \(FrameHandler.instanse)")
//        }
//    }
    
    override init() {
        
        super.init()
//        FrameHandler.instanse = self
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func setupCaptureSession() {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Error getting AVCaptureDeviceInput")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session = AVCaptureSession()
            self.session?.sessionPreset = .high
            self.session?.addInput(input)
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: .main)
            
            self.session?.addOutput(output)
            output.connections.first?.videoOrientation = .portrait
            self.session?.startRunning()
        }
    }
    
    func checkPermission() {
        print("check permission")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.permissionGranted = true
            
        case .notDetermined: // The user has not yet been asked for camera access.
            self.requestPermission()
            
            // Combine the two other cases into the default case
        default:
            self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        // Strong reference not a problem here but might become one in the future.
        print("Request permission")
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
//    deinit {
//        session?.stopRunning()
//    }
    
      
//    // The Core Image pipeline.
    public var ciContext: CIContext!
   
    
    // MARK: - LifeCycle Methods
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        intializeRequests()
//    }
    
//    // Create a request to detect face rectangles.
//    var facePoseRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
//        guard let face = request.results?.first as? VNFaceObservation else { return }
//        // Generate RGB color intensity values for the face rectangle angles.
//        self?.colors = AngleColors(roll: face.roll, pitch: face.pitch, yaw: face.yaw)
//    }
    
//    func intializeRequests() {
//        
//        // Create a request to detect face rectangles.
//        print("facePoseRequest")
//        facePoseRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
//            guard let face = request.results?.first as? VNFaceObservation else { return }
//            // Generate RGB color intensity values for the face rectangle angles.
//            self?.colors = AngleColors(roll: face.roll, pitch: face.pitch, yaw: face.yaw)
//        }
//        facePoseRequest.revision = VNDetectFaceRectanglesRequestRevision3
//        
//        // Create a request to segment a person from an image.
//        segmentationRequest = VNGeneratePersonSegmentationRequest()
//        segmentationRequest.qualityLevel = .balanced
//        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
//    }
    
//    private func processVideoFrame(_ framePixelBuffer: CVPixelBuffer) {
//        print("facePoseRequest 1")
//
//        // Perform the requests on the pixel buffer that contains the video frame.
//        try? requestHandler.perform([facePoseRequest, segmentationRequest],
//                                    on: framePixelBuffer,
//                                    orientation: .right)
//        
//        // Get the pixel buffer that contains the mask image.
//        guard let maskPixelBuffer =
//                segmentationRequest.results?.first?.pixelBuffer else { return }
//        
//        // Process the images.
//        blend(original: framePixelBuffer, mask: maskPixelBuffer)
//    }

    
    // Performs the blend operation.
//    private func blend(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) {
//        
//        // Remove the optionality from generated color intensities or exit early.
//        guard let colors = colors else { return }
//        
//        // Create CIImage objects for the video frame and the segmentation mask.
//        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
//        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
//        
//        // Scale the mask image to fit the bounds of the video frame.
//        let scaleX = originalImage.extent.width / maskImage.extent.width
//        let scaleY = originalImage.extent.height / maskImage.extent.height
//        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
//        
//        // Define RGB vectors for CIColorMatrix filter.
//        let vectors = [
//            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: colors.red),
//            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: colors.green),
//            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: colors.blue)
//        ]
//        
//        // Create a colored background image.
//        let backgroundImage = maskImage.applyingFilter("CIColorMatrix", parameters: vectors)
//        
//        // Blend the original, background, and mask images.
//        let blendFilter = CIFilter.blendWithRedMask()
//        blendFilter.inputImage = originalImage
//        blendFilter.backgroundImage = backgroundImage
//        blendFilter.maskImage = maskImage
//        
//        // Set the new, blended image as current.
//        currentCIImage = blendFilter.outputImage?.oriented(.left)
//        guard let cgImage = context.createCGImage(currentCIImage!, from: currentCIImage!.extent) else { return }
//        frameRate += 1
//        if frameRate % 3 == 0{
//            DispatchQueue.main.async { [unowned self] in
//                FrameHandler.instanse?.frame = cgImage
//            }
//        }else{
//            if self.frameRate > 60 {
//                self.frameRate = 0
//            }
//        }
//    }
    
}


extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Grab the pixelbuffer frame from the camera output
//        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
//        processVideoFrame(pixelBuffer)
        
        frameRate += 1
        if frameRate%3 == 0{
            guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else {
                return
            }
            
            // All UI updates should be/ must be performed on the main queue.
            DispatchQueue.main.async { [unowned self] in
                frame = cgImage
                // FrameHandler.instanse?.frame = cgImage
            }
        }
        else{
            if frameRate > 60 {
                frameRate = 0
            }
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}


