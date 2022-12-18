//
//  OCRTestPostProcessor.swift
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

import Vision

protocol OCRPostProcessor {
    func process(results: [VNRecognizedTextObservation]) -> [String]
}

class CarPlateOCRValidator: OCRPostProcessor {
    
    let confidence: Float
    let stringLength: Int
    
    init(confidence: Float, stringLength: Int) {
        self.confidence = confidence
        self.stringLength = stringLength
    }
    
    func process(results: [VNRecognizedTextObservation]) -> [String] {
        return results.compactMap {
            guard $0.confidence >= confidence, let string = $0.topCandidates(1).first?.string else { return nil }

            let punctuationFreeString = string
                //.components(separatedBy: .whitespacesAndNewlines).joined()
                //.components(separatedBy: .punctuationCharacters).joined()

            guard punctuationFreeString.count <= stringLength else { return nil }
            return punctuationFreeString
        }
    }
}
