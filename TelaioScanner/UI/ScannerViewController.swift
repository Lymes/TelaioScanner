//
//  ScannerViewController.swift
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
import Vision


class ScannerViewController: UIViewController {

    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var plateLabel: UILabel!
    
    private static let targetSize = TargetSize(width: 300, height: 50)
    
    private let captureService: VideoCaptureServiceType = VideoCaptureService(targetSize: targetSize)
    private let ocrService: OCRServiceType = OCRService(postProcessor: CarPlateOCRValidator())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inquadra numero di telaio"
        plateLabel.text = ""
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        scannerView.addGestureRecognizer(pinchRecognizer)
        startScan()
    }
    
    private func startScan() {
        captureService.start() { [weak self] result in
            switch result {
            case .accessDenied:
                guard let alert = self?.accessDeniedAlert else { return }
                self?.present(alert, animated: true)
            case .success:
                guard let frame = self?.scannerView.layer.bounds,
                      let videoPreviewLayer = self?.captureService.videoPreviewLayer else { return }
                videoPreviewLayer.frame = frame
                self?.scannerView.layer.addSublayer(videoPreviewLayer)
                self?.captureService.delegate = self
            }
        }
    }
    
    @objc
    private func pinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began: fallthrough
        case .changed: captureService.zoom(scaleFactor: pinch.scale, finished: false)
        case .ended: captureService.zoom(scaleFactor: pinch.scale, finished: true)
        default: break
        }
    }
    
    private lazy var accessDeniedAlert: UIAlertController = {
        let ac = UIAlertController(title: "Access Denied", message: "To use the app you must authorize using your camera", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Go To Settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return ac
    }()
    
    deinit {
        print("☠️ \(self) is deallocated.")
    }
}

extension ScannerViewController: VideoCaptureServiceDelegate {
    
    func dataOutput(frame: CVImageBuffer) {
        let width = CGFloat(CVPixelBufferGetWidth(frame))
        let height = CGFloat(CVPixelBufferGetHeight(frame))
        let targetRect = CGRect(x: (width - Self.targetSize.width) / 2.0, y: (height - Self.targetSize.height) / 2.0, width: Self.targetSize.width, height: Self.targetSize.height).insetBy(dx: 10, dy: 0)
        let image = CIImage(cvImageBuffer: frame)
        let cropped = image.cropped(to: targetRect).oriented(.upMirrored)
        self.ocrService.recognize(on: cropped) { [weak self] result in
            switch result {
            case .success(let strings):
                guard strings.count > 0 else { return }
                DispatchQueue.main.async {
                    self?.plateLabel.text = strings.joined(separator: ",")
                }
            case .failure( _ ):
                break
            }
        }
    }
}
