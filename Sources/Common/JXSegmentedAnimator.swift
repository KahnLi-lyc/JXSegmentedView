//
//  JXSegmentedAnimator.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2019/1/21.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import Foundation
import UIKit

@MainActor
open class JXSegmentedAnimator {
    open var duration: TimeInterval = 0.25
    open var progressClosure: (@MainActor (CGFloat) -> Void)?
    open var completedClosure: (@MainActor () -> Void)?
    private var displayLink: CADisplayLink?
    private var firstTimestamp: CFTimeInterval?
    private var isFinished = false

    public init() {}

    open func start() {
        guard displayLink == nil, !isFinished else { return }
        let target = JXSegmentedAnimationTarget(owner: self)
        let link = CADisplayLink(target: target, selector: #selector(JXSegmentedAnimationTarget.tick(_:)))
        displayLink = link
        link.add(to: .main, forMode: .common)
    }

    open func stop() {
        finish()
    }

    // Internal timestamp seam keeps completion/reentrancy tests independent of frame timing.
    func advance(timestamp: CFTimeInterval) {
        guard !isFinished else { return }
        if firstTimestamp == nil { firstTimestamp = timestamp }
        let percent = duration <= 0 ? 1 : (timestamp - firstTimestamp!) / duration
        if percent >= 1 {
            finish()
        } else {
            progressClosure?(CGFloat(max(0, percent)))
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        displayLink?.invalidate()
        displayLink = nil
        let progress = progressClosure
        let completed = completedClosure
        progressClosure = nil
        completedClosure = nil
        progress?(1)
        completed?()
    }
}

// CADisplayLink retains its target. The target must not retain the animator.
// If an owner disappears while running, the next main-run-loop tick invalidates
// the orphaned link; no UIKit or user callback is invoked from deinit.
@MainActor
private final class JXSegmentedAnimationTarget: NSObject {
    weak var owner: JXSegmentedAnimator?
    init(owner: JXSegmentedAnimator) { self.owner = owner }
    @objc func tick(_ link: CADisplayLink) {
        guard let owner else { link.invalidate(); return }
        owner.advance(timestamp: link.timestamp)
    }
}
