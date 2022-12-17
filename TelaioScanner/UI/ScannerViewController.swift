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
import Combine

class ScannerViewController: UIViewController {
    
    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var plateLabel: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = ScannerViewModel(targetSize: ScannerViewController.targetSize)
    private static let targetSize = TargetSize(width: 300, height: 50)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inquadra numero di telaio"
        plateLabel.text = ""
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        scannerView.addGestureRecognizer(pinchRecognizer)
        setupObservers()
        viewModel.startScan()
    }
    
    private func setupObservers() {
        viewModel.$recognizedString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recognizedString in
                self?.plateLabel.text = recognizedString
            }.store(in: &cancellables)
        
        viewModel.$accessDenied
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flag in
                guard flag, let alert = self?.accessDeniedAlert else { return }
                self?.present(alert, animated: true)
            }.store(in: &cancellables)
        
        viewModel.$captureStarted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flag in
                guard flag, let frame = self?.scannerView.layer.bounds,
                      let videoPreviewLayer = self?.viewModel.previewLayer else { return }
                videoPreviewLayer.frame = frame
                self?.scannerView.layer.addSublayer(videoPreviewLayer)
            }.store(in: &cancellables)
    }
    
    @objc
    private func pinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began: fallthrough
        case .changed: viewModel.zoom(scaleFactor: pinch.scale, finished: false)
        case .ended: viewModel.zoom(scaleFactor: pinch.scale, finished: true)
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
