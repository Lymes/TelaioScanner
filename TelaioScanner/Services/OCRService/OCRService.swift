//
//  OCRService.swift
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

protocol OCRServiceType {
    func recognize(on image: CIImage, completion: @escaping (Result<[String], Error>) -> Void)
    func recognize(on buffer: CVPixelBuffer, completion: @escaping (Result<[String], Error>) -> Void)
}

final class OCRService: OCRServiceType {
    private enum OCRError: Error {
        case requestIsNil
        case cgImageIsNil
    }

    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let textRecognitionRequest = VNRecognizeTextRequest() { [weak self] req, err in
            self?.handleDetectedText(request: req, error: err)
        }
        textRecognitionRequest.recognitionLanguages = ["en-US"]
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.minimumTextHeight = 0.2
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesCPUOnly = false

        return textRecognitionRequest
    }()

    private var postProcessor: OCRPostProcessor
    private var completion: ((Result<[String], Error>) -> Void)?

    init(postProcessor: OCRPostProcessor) {
        self.postProcessor = postProcessor
    }

    // MARK: public methods

    func recognize(on image: CIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        self.completion = completion
        performRecognition(request: textRecognitionRequest, image: image)
    }

    func recognize(on buffer: CVPixelBuffer, completion: @escaping (Result<[String], Error>) -> Void) {
        self.completion = completion
        performRecognition(request: textRecognitionRequest, buffer: buffer)
    }

    // MARK: private methods

    private func performRecognition(request: VNRequest, buffer: CVPixelBuffer) {
        DispatchQueue.global(qos: .userInitiated).async {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
            do {
                try imageRequestHandler.perform([request])
            } catch {
                self.completion?(.failure(error))
                return
            }
        }
    }
    
    private func performRecognition(request: VNRequest, image: CIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let imageRequestHandler = VNImageRequestHandler(ciImage: image,
                                                            options: [:])
            do {
                try imageRequestHandler.perform([request])
            } catch {
                self.completion?(.failure(error))
                return
            }
        }
    }

    private func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            completion?(.failure(error))
            return
        }
        guard let request = request, let results = request.results as? [VNRecognizedTextObservation] else {
            completion?(.failure(OCRError.requestIsNil))
            return
        }
        completion?(.success( postProcessor.process(results: results)))
    }
}
