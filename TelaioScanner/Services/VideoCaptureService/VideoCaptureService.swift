//
//  VideoCaptureService.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 17/12/2022.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import AVFoundation

protocol VideoCaptureServiceType {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { get }
    var delegate: VideoCaptureServiceDelegate? { get nonmutating set }
    func start(completion: @escaping (VideoCaptureService.CaptureResult) -> Void)
    func stop()
    func zoom(scaleFactor: CGFloat, finished: Bool)
}

protocol VideoCaptureServiceDelegate: AnyObject {
    func dataOutput(frame: CVImageBuffer)
}

typealias TargetSize = CGSize

final class VideoCaptureService: NSObject, VideoCaptureServiceType {
    enum CaptureResult {
        case success
        case accessDenied
    }
    
    // MARK: public properties

    weak var delegate: VideoCaptureServiceDelegate?

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        let layer = ScannerOverlayPreviewLayer(session: session)
        layer.maskSize = targetSize
        layer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.targetCornerRadius = 10
        layer.lineCap = .round
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }

    // MARK: private properties

    private let targetSize: TargetSize
    private let minimumZoom: CGFloat = 1.0
    private let maximumZoom: CGFloat = 5.0
    private var lastZoomFactor: CGFloat = 1.0
    private var cameraDevice: AVCaptureDevice?
    private let session = AVCaptureSession()
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
   
    // MARK: public methods
    
    init(targetSize: TargetSize) {
        self.targetSize = targetSize
    }

    func start(completion: @escaping (CaptureResult) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            if response {
                self?.setUpCaptureSession()
                completion(.success)
            } else {
                completion(.accessDenied)
            }
        }
    }
    
    func stop() {
        session.stopRunning()
    }
    
    func zoom(scaleFactor: CGFloat, finished: Bool) {
        guard let device = cameraDevice else { return }
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        let newScaleFactor = minMaxZoom(scaleFactor * lastZoomFactor)
        if finished {
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        } else {
            update(scale: newScaleFactor)
        }
    }
    
    // MARK: private methods
    
    private func setUpCaptureSession() {
        session.sessionPreset = .medium
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            cameraDevice = captureDevice
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                session.addInput(input)
            } catch{
                print(error.localizedDescription)
            }
            
            let output = AVCaptureVideoDataOutput()
            session.addOutput(output)
            
            output.setSampleBufferDelegate(self, queue: dataOutputQueue)
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            let videoConnection = output.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            if videoConnection?.isVideoMirroringSupported ?? false
            {
                videoConnection?.isVideoMirrored = true
            }
            
            session.startRunning()
        }
    }
}

extension VideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        delegate?.dataOutput(frame: imageBuffer)
    }
}
