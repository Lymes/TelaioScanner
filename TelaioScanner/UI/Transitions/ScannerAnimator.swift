//
//  ScannerAnimator.swift
//  TelaioScanner
//
//  Created by Leonid Mesentsev on 18/12/22.
//

import UIKit

class ScannerAnimator: NSObject {
    
}

extension ScannerAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let toVC = transitionContext.viewController(forKey: .to) as? FirstViewController,
           let fromVC = transitionContext.viewController(forKey: .from) as? ScannerViewController {
            transition(fromVC: fromVC, toVC: toVC, transitionContext: transitionContext)
        }
        else if let toVC = transitionContext.viewController(forKey: .to) as? ScannerViewController,
                let fromVC = transitionContext.viewController(forKey: .from) as? FirstViewController {
            transition(fromVC: fromVC, toVC: toVC, transitionContext: transitionContext)
        }
    }
    
    func transition(fromVC: FirstViewController, toVC: ScannerViewController, transitionContext: UIViewControllerContextTransitioning) {
        guard let snapshotFrom = fromVC.view.snapshotView(afterScreenUpdates: true) else { return }
        guard let _ = toVC.view.snapshotView(afterScreenUpdates: true) else { return }
        snapshotFrom.frame = fromVC.view.frame

        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshotFrom)
        toVC.view.alpha = 0

        let scaleX = toVC.scannerView.frame.width / fromVC.scanButton.frame.width
        let scaleY = toVC.scannerView.frame.height / fromVC.scanButton.frame.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                
        let toView = transitionContext.view(forKey: .to)
        if let view = toView {
            transitionContext.containerView.addSubview(view)
        }

        let duration = transitionDuration(using: transitionContext)
        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    snapshotFrom.transform = transform
                    snapshotFrom.center = toVC.scannerView.center
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    toVC.view.alpha = 1
                }
            },
            completion: { _ in
                snapshotFrom.removeFromSuperview()
                if transitionContext.transitionWasCancelled {
                    toVC.view.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    func transition(fromVC: ScannerViewController, toVC: FirstViewController, transitionContext: UIViewControllerContextTransitioning) {
        guard let snapshotFrom = fromVC.view.snapshotView(afterScreenUpdates: true) else { return }
        guard let _ = toVC.view.snapshotView(afterScreenUpdates: true) else { return }
        snapshotFrom.frame = fromVC.view.frame
        
        let scaleX = toVC.scanButton.frame.width / fromVC.scannerView.frame.width
        let scaleY = toVC.scanButton.frame.height / fromVC.scannerView.frame.height
        let transY = fromVC.scannerView.center.y - toVC.view.frame.height / 2.0 + 30 / scaleY
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY).translatedBy(x: 0, y: transY)
        
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshotFrom)
        toVC.view.alpha = 0
        fromVC.view.subviews.forEach { $0.isHidden = true }
        
        let toView = transitionContext.view(forKey: .to)
        if let view = toView {
            transitionContext.containerView.addSubview(view)
        }
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: {
            snapshotFrom.transform = transform
            toVC.view.alpha = 1
            snapshotFrom.alpha = 0
        }, completion: { _ in
            snapshotFrom.removeFromSuperview()
            if transitionContext.transitionWasCancelled {
                toVC.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
