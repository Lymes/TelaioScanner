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
        guard let snapshot = toVC.view.snapshotView(afterScreenUpdates: true) else { return }
        let originFrame = fromVC.scanButton.frame
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        snapshot.frame = originFrame
        snapshot.layer.cornerRadius = fromVC.scanButton.layer.cornerRadius
        snapshot.layer.masksToBounds = true
        
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        toVC.view.isHidden = true
        
        let toView = transitionContext.view(forKey: .to)
        
        if let view = toView {
            transitionContext.containerView.addSubview(view)
        }
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: {
            snapshot.frame = finalFrame
            snapshot.layer.cornerRadius = 0
        }) { (success) in
            toVC.view.isHidden = false
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    func transition(fromVC: ScannerViewController, toVC: FirstViewController, transitionContext: UIViewControllerContextTransitioning) {
        guard let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else { return }
        
        let originFrame = fromVC.view.frame
        let containerView = transitionContext.containerView
        let finalFrame =  toVC.scanButton.frame
        
        snapshot.frame = originFrame
        snapshot.layer.cornerRadius = 0
        snapshot.layer.masksToBounds = true
        
        fromVC.view.subviews.forEach { $0.removeFromSuperview() }
        
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        toVC.view.isHidden = true

        let toView = transitionContext.view(forKey: .to)
        
        if let view = toView {
            transitionContext.containerView.addSubview(view)
        }
        
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            snapshot.frame = finalFrame
            snapshot.layer.cornerRadius = toVC.scanButton.layer.cornerRadius
        }) { (success) in
            toVC.view.isHidden = false
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
