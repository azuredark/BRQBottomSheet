//
//  BRQBottomSheetViewController.swift
//  BRQBottomSheet
//
//  Created by Bruno Faganello Neto on 17/07/19.
//  Copyright © 2019 Faganello. All rights reserved.
//

import UIKit

public protocol BRQBottomSheetViewControllerPresentable {
    var viewCornerRadius: CGFloat { get set }
    var maxTopConstant: CGFloat { get set }
    
    var animationTransitionDuration: TimeInterval { get set }
    var backgroundColor: UIColor { get set }
}

public class BRQBottomSheetViewController: UIViewController {

    //-----------------------------------------------------------------------------
    // MARK: - Outlets
    //-----------------------------------------------------------------------------
    
    @IBOutlet weak private var contentView: UIView!
    @IBOutlet weak private var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak private var contentViewHeight: NSLayoutConstraint!
    
    //-----------------------------------------------------------------------------
    // MARK: - Public properties
    //-----------------------------------------------------------------------------
    
    let viewModel: BRQBottomSheetViewControllerPresentable
    
    //-----------------------------------------------------------------------------
    // MARK: - Private properties
    //-----------------------------------------------------------------------------
    
    private let childViewController: UIViewController
    private var originBeforeAnimation: CGRect = .zero
    
    //-----------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------
    
    public init(viewModel: BRQBottomSheetViewControllerPresentable, childViewController: UIViewController) {
        self.viewModel = viewModel
        self.childViewController = childViewController
        super.init(
            nibName: String(describing: BRQBottomSheetViewController.self),
            bundle: Bundle(for: BRQBottomSheetViewController.self)
        )
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//-----------------------------------------------------------------------------
// MARK: - Lifecycle
//-----------------------------------------------------------------------------

 extension BRQBottomSheetViewController {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        contentView.alpha = 0
        configureChild()
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(BRQBottomSheetViewController.panGesture))
        contentView.addGestureRecognizer(gesture)
        gesture.delegate = self
        
        contentViewBottomConstraint.constant = -childViewController.view.frame.height
        view.layoutIfNeeded()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tableView = containsTableView() {
            contentViewHeight.constant = tableView.contentSize.height
            view.layoutIfNeeded()
        } else {
            contentViewHeight.isActive = false
        }
        
        contentView.fadeIn()
        contentViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.view.layoutIfNeeded()
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.roundCorners([.topLeft, .topRight], radius: 20)
        originBeforeAnimation = contentView.frame
    }
}

//-----------------------------------------------------------------------------
// MARK: - Private methods
//-----------------------------------------------------------------------------

private extension BRQBottomSheetViewController {
    
    private func configureChild() {
        addChild(childViewController)
        contentView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            childViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func shouldDismissWithGesture(_ recognizer: UIPanGestureRecognizer) -> Bool {
        return recognizer.state == .ended
    }
    
    private func dismissViewController() {
        contentViewBottomConstraint.constant = -childViewController.view.frame.height
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = .clear
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: view)
        
        if shouldDismissWithGesture(recognizer) {
            dismissViewController()
        } else {
            if point.y <= originBeforeAnimation.origin.y {
                recognizer.isEnabled = false
                recognizer.isEnabled = true
                return
            }
            contentView.frame = CGRect(x: 0, y: point.y, width: view.frame.width, height: view.frame.height)
        }
    }
    
    private func containsTableView() -> UITableView? {
        for view in childViewController.view.subviews {
            if let tableView = view as? UITableView {
                return tableView
            }
        }
        return nil
    }
}

//-----------------------------------------------------------------------------
// MARK: - Event handling
//-----------------------------------------------------------------------------

extension BRQBottomSheetViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        
        return false
    }
    
    @IBAction private func topViewTap(_ sender: Any) {
        dismissViewController()
    }
}