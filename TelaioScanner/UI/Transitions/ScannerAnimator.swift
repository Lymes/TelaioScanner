//
//  ScannerAnimator.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 18/12/22.
//

import UIKit

protocol ResizeTransitable where Self: UIViewController {
    var viewToResize: UIView { get }
    var viewToHide: [UIView] { get }
}

class ScannerAnimator: NSObject {
    
}

extension ScannerAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? ResizeTransitable,
              let fromVC = transitionContext.viewController(forKey: .from) as? ResizeTransitable else { return }
        transition(fromVC: fromVC, toVC: toVC, transitionContext: transitionContext)
    }

    func transition(fromVC: ResizeTransitable, toVC: ResizeTransitable, transitionContext: UIViewControllerContextTransitioning) {
        fromVC.viewToHide.forEach { $0.alpha = 0 }
        guard let snapshotFrom = fromVC.viewToResize.snapshotView(afterScreenUpdates: true) else { return }
        snapshotFrom.frame = fromVC.viewToResize.frame
        toVC.view.setNeedsLayout()
        toVC.view.layoutIfNeeded()
        let transform = CGAffineTransform(from: fromVC.viewToResize.globalFrame, to: toVC.viewToResize.globalFrame)
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshotFrom)
        toVC.view.alpha = 0
        fromVC.viewToResize.alpha = 0
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration) {
            snapshotFrom.transform = transform
        } completion: { _ in
            toVC.view.alpha = 1
            fromVC.viewToResize.alpha = 1
            fromVC.viewToHide.forEach { $0.alpha = 1 }
            snapshotFrom.removeFromSuperview()
            if transitionContext.transitionWasCancelled {
                toVC.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

extension CGAffineTransform {
    init(from source: CGRect, to destination: CGRect) {
        self = CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
}

extension UIView {
    var globalFrame: CGRect {
        return self.superview?.convert(self.frame, to: nil) ?? .zero
    }
}
