//
//  ScannerSegue.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 18/12/22.
//

import UIKit

final class ScannerSegue: UIStoryboardSegue {
    override func perform() {
        destination.transitioningDelegate = self
        super.perform()
    }
}

extension ScannerSegue: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return ScannerAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScannerAnimator()
    }
}
