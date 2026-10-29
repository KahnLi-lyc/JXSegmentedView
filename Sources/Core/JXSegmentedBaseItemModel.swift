//
//  JXSegmentedBaseItemModel.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2018/12/26.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import Foundation
import UIKit

@MainActor
open class JXSegmentedBaseItemModel {
    open var index: Int = 0
    open var isSelected: Bool = false
    open var itemWidth: CGFloat = 0
    /// 指示器视图Frame转换到cell
    open var indicatorConvertToItemFrame: CGRect = CGRect.zero
    open var isItemTransitionEnabled: Bool = true
    open var isSelectedAnimable: Bool = false
    open var selectedAnimationDuration: TimeInterval = 0
    /// 是否正在进行过渡动画
    open var isTransitionAnimating: Bool {
        get { transitionRequested && (!tracksAnimator || transitionAnimator != nil) }
        set {
            transitionRequested = newValue
            tracksAnimator = false
            transitionAnimator = nil
        }
    }
    private var transitionRequested = false
    private var tracksAnimator = false
    private weak var transitionAnimator: JXSegmentedAnimator?

    // A released cell/animator cannot leave a retained model permanently animating.
    // Manual writes retain their existing behavior; only library-started animations track ownership.
    func trackTransition(with animator: JXSegmentedAnimator) {
        isTransitionAnimating = true
        tracksAnimator = true
        transitionAnimator = animator
    }
    func finishTransition(with animator: JXSegmentedAnimator) {
        guard tracksAnimator, transitionAnimator === animator else { return }
        isTransitionAnimating = false
    }
    open var isItemWidthZoomEnabled: Bool = false
    open var itemWidthNormalZoomScale: CGFloat = 0
    open var itemWidthCurrentZoomScale: CGFloat = 0
    open var itemWidthSelectedZoomScale: CGFloat = 0

    public init() {
    }
}
