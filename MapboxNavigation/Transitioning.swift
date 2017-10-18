import UIKit

class Interactor: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

class DismissAnimator : NSObject { }
extension DismissAnimator : UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        let containerView = transitionContext.containerView
        
        let point = CGPoint(x: 0, y: toVC.view.bounds.maxY)
        let height = fromVC.view.bounds.height-toVC.view.frame.minY
        let finalFrame = CGRect(origin: point, size: CGSize(width: fromVC.view.bounds.width, height: height))
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
            fromVC.view.frame = finalFrame
            containerView.backgroundColor = .clear
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class PresentAnimator : NSObject {
    var height: CGFloat?
    
    convenience init(height: CGFloat) {
        self.init()
        self.height = height
    }
}

extension PresentAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        
        containerView.backgroundColor = .clear
        toView.frame = CGRect(x: 0, y: containerView.bounds.height,
                              width: containerView.bounds.width, height: height ?? containerView.bounds.midY)
        
        containerView.addSubview(toView)
        let tap = UITapGestureRecognizer(target: toVC, action: #selector(FeedbackViewController.handleDismissTap(sender:)))
        containerView.addGestureRecognizer(tap)
        
        let yPoint = CGFloat(height != nil ? fromVC.view.bounds.height - height! : fromVC.view.bounds.midY)
        let point = CGPoint(x: 0, y: yPoint)
        let finalFrame = CGRect(origin: point, size: CGSize(width: fromVC.view.bounds.width,
                                                            height: height ?? fromVC.view.bounds.midY))
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
            toView.frame = finalFrame
            containerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

@objc protocol DismissDraggable: UIViewControllerTransitioningDelegate {
    var interactor: Interactor { get }
    @objc optional func handleDismissPan(_ sender: UIPanGestureRecognizer)
}

fileprivate extension Selector {
    static let handleDismissDrag = #selector(UIViewController.handleDismissPan(_:))
}

extension DismissDraggable where Self: UIViewController {
    func enableDraggableDismiss() {
        let pan = UIPanGestureRecognizer(target: self, action: .handleDismissDrag)
        view.addGestureRecognizer(pan)
    }
}

fileprivate extension UIViewController {
    
    @objc func handleDismissPan(_ sender: UIPanGestureRecognizer) {
        self.handlePan(sender)
    }
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let vc = self as? DismissDraggable else { return }
        
        let finishThreshold: CGFloat = 0.4
        let translation = sender.translation(in: view)
        let progress = translation.y / view.bounds.height
        
        switch sender.state {
        case .began:
            vc.interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            vc.interactor.shouldFinish = progress > finishThreshold
            vc.interactor.update(progress)
        case .cancelled:
            vc.interactor.hasStarted = false
            vc.interactor.cancel()
        case .ended:
            vc.interactor.hasStarted = false
            vc.interactor.shouldFinish ? vc.interactor.finish() : vc.interactor.cancel()
        default:
            break
        }
    }
}
