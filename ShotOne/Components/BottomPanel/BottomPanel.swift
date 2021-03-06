//
//  BottomPanel.swift
//  ShotOne
//
//  Created by Ivan Zinovyev on 23/04/2019.
//  Copyright © 2019 Ivan Zinovyev. All rights reserved.
//

import UIKit

class BottomPanel: NSObject {

    // MARK: - Constants
    
    private enum Constants {
        
        enum Animation {
            
            enum Duration {
                
                static let slow: TimeInterval = 0.5
                
                static let fast: TimeInterval = 0.25
                
            }
            
            static let options: UIView.AnimationOptions = [
                .curveEaseOut,
                .beginFromCurrentState,
                .allowUserInteraction
            ]
            
            static let initialSpringVelocity: CGFloat = 0
            
            static let springDamping: CGFloat = 0.75
            
        }
        
        enum TranslationMultiplier {
            
            static let isOutside: CGFloat = 0.1
            
            static let isNotOutside: CGFloat = 1
            
        }
        
        static let transitionThreshold: CGFloat = 100
        
    }
    
    // MARK: - Constraints
    
    private var topConstraint: NSLayoutConstraint?
    
    // MARK: - Delegate
    
    weak var delegate: BottomPanelDelegate?
    
    // MARK: - Properties
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
        }
    }
    
    private let contentViewController: UIViewController
    
    private let scrollView: UIScrollView?
    
    private let positions: [CGFloat]
    
    private lazy var maxPosition = positions.max() ?? 0
    
    private lazy var minPosition = positions.min() ?? 0
    
    private var parentViewController: UIViewController?
    
    private var isOutside = false

    private var shouldDelegate = false
    
    // MARK: - Init
    
    init(contentViewController: UIViewController,
         positions: [CGFloat],
         scrollView: UIScrollView? = nil) {
        
        self.contentViewController = contentViewController
        self.positions = positions
        self.scrollView = scrollView
        
        super.init()
        
        addPanGestureRecognizers()
    }
    
}

// MARK: - Computed Properties

extension BottomPanel {

    private var contentView: UIView {
        return contentViewController.view
    }

    private var currentPosition: CGFloat {
        guard let parentViewController = parentViewController else { return 0 }
        return parentViewController.view.frame.maxY - contentView.frame.origin.y
    }
    
    private var isMaxPosition: Bool {
        return currentPosition == maxPosition
    }

}

// MARK: - Public

extension BottomPanel {

    func embed(in parentViewController: UIViewController) {
        guard let lastPosition = positions.last else { return }

        self.parentViewController = parentViewController

        parentViewController.addChild(contentViewController)
        parentViewController.view.addSubview(contentView)
        contentViewController.didMove(toParent: parentViewController)

        let topConstraint = contentView.topAnchor.constraint(equalTo: parentViewController.view.topAnchor)

        contentView.activate {[
            $0.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor),
            $0.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor),
            $0.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor),
            topConstraint
        ]}

        contentView.layer.masksToBounds = true
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        self.topConstraint = topConstraint

        change(position: lastPosition)
    }

}

// MARK: - UIGestureRecognizerDelegate

extension BottomPanel: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let scrollView = scrollView else { return false }
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let isZeroContentOffset = scrollView.contentOffset.y == 0
        let isDownDirection = gestureRecognizer.direction(in: contentView) == .down
        
        let isScrollDisabled = (isMaxPosition && isZeroContentOffset && isDownDirection) || !isMaxPosition
        setScroll(isEnabled: !isScrollDisabled)
        
        return false
    }
    
}

// MARK: - Gestures

private extension BottomPanel {
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            onPanChanged(recognizer)
        case .cancelled, .ended, .failed:
            onPanCompleted(recognizer)
        default:
            return
        }
    }
    
    @objc func handleScroll(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = scrollView else { return }

        let contentOffset = scrollView.contentOffset.y
        let isDownDirection = recognizer.direction(in: contentView) == .down

        guard (isDownDirection && contentOffset <= 0) || shouldDelegate else { return }
        
        if !shouldDelegate {
            shouldDelegate = true
            recognizer.setTranslation(CGPoint(x: 0, y: -contentOffset), in: contentView)
        }
        
        scrollView.contentOffset.y = 0

        handlePan(recognizer)
    }
    
    func onPanChanged(_ recognizer: UIPanGestureRecognizer) {
        guard let parentViewController = parentViewController else { return }
        
        let min = parentViewController.view.frame.maxY - maxPosition
        let max = parentViewController.view.frame.maxY - minPosition

        let multiplier: CGFloat = isOutside
            ? Constants.TranslationMultiplier.isOutside
            : Constants.TranslationMultiplier.isNotOutside
        
        let translation = recognizer.translation(in: contentView).y
        let delta = translation * multiplier
        let targetY = contentView.frame.origin.y + delta

        isOutside = targetY > max || targetY < min
        
        change(y: targetY)
        
        recognizer.setTranslation(.zero, in: contentView)
    }

    func onPanCompleted(_ recognizer: UIPanGestureRecognizer) {
        defer { shouldDelegate = false }

        let velocity = recognizer.velocity(in: contentView).y
        
        if abs(velocity) < Constants.transitionThreshold {
            moveToNearestPosition()
            return
        }
        
        guard let nextPosition = nearPosition(for: velocity) else { return }

        if isOutside {
            normalTransition(to: nextPosition, duration: Constants.Animation.Duration.fast)
        } else {
            springTransition(to: nextPosition, duration: Constants.Animation.Duration.slow)
        }
    }
    
}

// MARK: - Animations

private extension BottomPanel {
    
    func normalTransition(to position: CGFloat,
                          duration: TimeInterval) {
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: Constants.Animation.options,
                       animations: { [weak self] in
            self?.change(position: position)
        }, completion: { [weak self] _ in
            self?.scrollToTopIfNeeded()
        })
    }
    
    func springTransition(to position: CGFloat,
                          duration: TimeInterval) {
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: Constants.Animation.springDamping,
                       initialSpringVelocity: Constants.Animation.initialSpringVelocity,
                       options: Constants.Animation.options,
                       animations: { [weak self] in
            self?.change(position: position)
        }, completion: { [weak self] _ in
            self?.scrollToTopIfNeeded()
        })
    }
    
}

// MARK: - Private

private extension BottomPanel {
    
    func addPanGestureRecognizers() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        recognizer.delegate = self
        contentViewController.view.addGestureRecognizer(recognizer)
        
        guard let scrollView = scrollView else { return }
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScroll))
    }

    func change(position: CGFloat) {
        guard let parentViewController = parentViewController else { return }
        change(y: parentViewController.view.frame.maxY - position)
        setScroll(isEnabled: true)
    }
    
    func change(y: CGFloat) {
        topConstraint?.constant = y
        parentViewController?.view.layoutIfNeeded()
        adjustCornerRadius()
        
        delegate?.didChange(state: currentPosition, isMaxPosition: isMaxPosition)
    }
    
    func adjustCornerRadius() {
        let safeAreaInsets = UIApplication.shared.safeAreaInsets
        let normalizedDelta = (safeAreaInsets.top - contentView.safeAreaInsets.top) / safeAreaInsets.top
        contentView.layer.cornerRadius = normalizedDelta * cornerRadius
    }
    
    func nearPosition(for velocity: CGFloat) -> CGFloat? {
        let candidatePositions = self.candidatePositions(for: velocity)

        if !candidatePositions.isEmpty,
           let nearPositionIndex = candidatePositions.nearPositionIndex(for: currentPosition) {
            return candidatePositions[nearPositionIndex]
        } else if let nearPositionIndex = positions.nearPositionIndex(for: currentPosition) {
            return positions[nearPositionIndex]
        }
        
        return nil
    }

    func moveToNearestPosition() {
        if let nearPositionIndex = positions.nearPositionIndex(for: currentPosition) {
            normalTransition(to: positions[nearPositionIndex], duration: Constants.Animation.Duration.fast)
        }
    }

    func candidatePositions(for velocity: CGFloat) -> [CGFloat] {
        let currentPosition = self.currentPosition
        
        if velocity.isPositive {
            return positions.filter { $0 < currentPosition }
        } else if velocity.isNegative {
            return positions.filter { $0 > currentPosition }
        }
        
        return []
    }
    
    func scrollToTopIfNeeded() {
        setScroll(isEnabled: isMaxPosition)
        
        guard !isMaxPosition else { return }
        scrollView?.scrollToTop()
    }
    
    func setScroll(isEnabled: Bool) {
        guard let scrollView = scrollView else { return }
        scrollView.isScrollEnabled = isEnabled
        scrollView.showsVerticalScrollIndicator = isEnabled
    }
    
}

private extension Array where Element == CGFloat {
    
    func nearPositionIndex(for currentPosition: CGFloat) -> Int? {
        return enumerated()
            .map { ($0.offset, abs(currentPosition - $0.element)) }
            .min(by: { $0.1 < $1.1 })?
            .0
    }
    
}
