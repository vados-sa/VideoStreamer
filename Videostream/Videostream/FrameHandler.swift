//
//  FrameHandler.swift
//  LiveStream
//
//  Created by dos Santos, Vanessa on 07.08.26.
//

import AVFoundation
import CoreImage
import SwiftUI
import Combine

final class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var isRunning = false
    //@Published var isConnected = false

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let outputQueue = DispatchQueue(label: "camera.output.queue")
    private let context = CIContext()

    private var permissionGranted = false
    private var isConfigured = false
    
    private lazy var ws: WebSocketManager = {
        let url = URL(string: "ws://127.0.0.1:8000/ws/videostream")
        return WebSocketManager(url: url!)
    }()

    override init() {
        super.init()
        checkPermission()
    }

    // MARK: - Public API

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.checkPermission()
            guard self.permissionGranted else { return } // instead of return, could be to call checkPermission again or show a message. - check

            if !self.isConfigured {
                self.setupSession()
                self.isConfigured = true
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
            
            self.ws.connect()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
            
//            self.outputQueue.sync {}
            
            self.ws.disconnect()
        }
    }

    // MARK: - Setup

    private func checkPermission() { // might need rework - https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app#Request-authorization
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.permissionGranted = granted
            }
        default:
            permissionGranted = false
        }
    }

    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(videoDeviceInput)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Frame conversion

    private func cgImage(from sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    func jpegData(from sampleBuffer: CMSampleBuffer, compression: CGFloat = 0.6) -> Data? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: compression)
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
//        print(sampleBuffer)
        // 1) Send frame to backend
        guard let compressedFrames = jpegData(from: sampleBuffer) else {return}
        self.ws.sendFrames(frames: compressedFrames)

        // 2) Optional local preview in SwiftUI
        guard let image = cgImage(from: sampleBuffer) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.frame = image
        }
    }
}
