//
//  ScannerViewModel.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 17/12/22.
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

import Combine
import CoreImage
import AVFoundation

final class ScannerViewModel: NSObject, VideoCaptureServiceDelegate {
    
    @Published
    private(set) var recognizedString: String = ""
    
    private let targetSize: TargetSize
    private let ocrService: OCRServiceType = OCRService(postProcessor: CarPlateOCRValidator())
    private let captureService: VideoCaptureServiceType
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        captureService.videoPreviewLayer
    }
    
    init(targetSize: TargetSize) {
        self.targetSize = targetSize
        self.captureService = VideoCaptureService(targetSize: targetSize)
    }
    
    func startScan(completion: @escaping (VideoCaptureService.CaptureResult) -> Void) {
        captureService.start() { [weak self] result in
            switch result {
            case .accessDenied:
                completion(result)
            case .success:
                completion(result)
                self?.captureService.delegate = self
            }
        }
    }
    
    func zoom(scaleFactor: CGFloat, finished: Bool) {
        captureService.zoom(scaleFactor: scaleFactor, finished: finished)
    }
    
    func dataOutput(frame: CVImageBuffer) {
        let width = CGFloat(CVPixelBufferGetWidth(frame))
        let height = CGFloat(CVPixelBufferGetHeight(frame))
        let targetRect = CGRect(x: (width - targetSize.width) / 2.0, y: (height - targetSize.height) / 2.0, width: targetSize.width, height: targetSize.height).insetBy(dx: 10, dy: 0)
        let image = CIImage(cvImageBuffer: frame)
        let cropped = image.cropped(to: targetRect).oriented(.upMirrored)
        self.ocrService.recognize(on: cropped) { [weak self] result in
            switch result {
            case .success(let strings):
                guard strings.count > 0 else { return }
                self?.recognizedString = strings.joined(separator: ",")
            case .failure( _ ):
                break
            }
        }
    }
}
