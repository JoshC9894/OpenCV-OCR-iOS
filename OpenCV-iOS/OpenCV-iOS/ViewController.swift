//
//  ViewController.swift
//  OpenCV-iOS
//
//  Created by Joshua Colley on 22/10/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    var cameraWrapper: UIView!
    
    var videoInput: AVCaptureDeviceInput!
    var videoOutput: AVCaptureVideoDataOutput!
    
    var cameraOutput = AVCapturePhotoOutput()
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    
    var cvBuffer: CVPixelBuffer?
    var cmSampleBuffer: CMSampleBuffer?
    
    var detectedRect: VNRectangleObservation?
    
    @IBOutlet weak var cameraButton: UIButton!
    
    // MARK: - Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraWrapper = UIView(frame: self.view.bounds)
        self.view.addSubview(cameraWrapper)
        self.startLiveVideo()
        
        cameraButton.layer.cornerRadius = cameraButton.frame.height / 2.0
        self.view.bringSubviewToFront(cameraButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.session.startRunning()
        self.detectRect()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.session.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        cameraWrapper.layer.sublayers?[0].frame = cameraWrapper.bounds
    }
    
    // MARK: - Actions
    @IBAction func cameraButtonAction(_ sender: Any) {
        captureImage()
    }
    
    // MARK: - Helper Methods
    fileprivate func captureImage() {
        guard let rect = detectedRect else { return }
        self.session.stopRunning()
    }
}

// MARK: - Video Layer
extension ViewController {
    fileprivate func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        // Input
        if self.videoInput == nil {
            self.videoInput = try? AVCaptureDeviceInput(device: device)
            self.session.addInput(self.videoInput)
        }
        
        // Output
        if self.videoOutput == nil {
            self.videoOutput = AVCaptureVideoDataOutput()
            let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
            
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput.setSampleBufferDelegate(self, queue: queue)
            self.session.addOutput(self.videoOutput)
            let connection = videoOutput.connection(with: .video)
            connection?.videoOrientation = .portrait
        }
        
        // Start Capture Session
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        cameraWrapper.layer.addSublayer(layer)
    }
}

// MARK: - Video Output Delegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.cmSampleBuffer = sampleBuffer
        self.cvBuffer = cvBuffer
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvBuffer,
                                                        orientation: .downMirrored,
                                                        options: requestOptions)
        try? imageRequestHandler.perform(self.requests)
    }
}

// MARK: - Rectangle Detection
extension ViewController {
    fileprivate func detectRect() {
        let rectRequests = VNDetectRectanglesRequest { (request, error) in
            if error == nil {
                self.rectRequestHandler(request: request)
            }
        }
        self.requests = [rectRequests]
    }
    
    fileprivate func rectRequestHandler(request: VNRequest) {
        guard let observations = request.results else { return }
        let result = observations.map({ $0 as? VNRectangleObservation })
        
        DispatchQueue.main.async {
            self.cameraWrapper.layer.sublayers?.removeSubrange(1...)
            result.forEach { (rect) in
                guard let box = rect else { return }
                self.detectedRect = box
                let shape = FrameHelper.getShape(rect: box, frame: self.cameraWrapper.bounds)
                self.cameraWrapper.layer.addSublayer(shape)
            }
        }
    }
}

