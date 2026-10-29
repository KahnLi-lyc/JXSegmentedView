import UIKit
import JXSegmentedView

/// A lazy list is a real scrolling view; lifecycle text comes only from container callbacks.
@MainActor
final class PageList: UIView, JXSegmentedListContainerViewListDelegate, JXSegmentedListContainerViewDataSource, JXSegmentedViewDelegate {
    let index: Int
    private let name: String
    private let lifecycle: @MainActor (String) -> Void
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let innerObservation = UILabel()
    private var innerCallbacks = 0
    private var innerEvents: [String] = []
    private weak var innerHostController: UIViewController?
    private weak var embeddedController: UIViewController?
    private var outerVisible = false
    private var outerPending: Bool?
    private var embeddedVisible = false
    private var embeddedPending: Bool?
    var innerDidAppearCount: Int { innerEvents.filter { $0.hasPrefix("didAppear:") }.count }
    var innerDidDisappearCount: Int { innerEvents.filter { $0.hasPrefix("didDisappear:") }.count }
    var innerLifecycleSummary: String { "nested\(index)DidAppear=\(innerDidAppearCount) nested\(index)DidDisappear=\(innerDidDisappearCount)" }
    var observedTitle: String { name }
    private var innerSource: JXSegmentedTitleDataSource?
    private var innerSegmented: JXSegmentedView?
    private var innerContainer: JXSegmentedListContainerView?
    private let nestedType: JXSegmentedListContainerType?

    init(index: Int, name: String, nestedType: JXSegmentedListContainerType? = nil, lifecycle: @escaping @MainActor (String) -> Void) {
        self.index = index
        self.name = name
        self.nestedType = nestedType
        self.lifecycle = lifecycle
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 18
        clipsToBounds = true
        accessibilityIdentifier = "page.\(index)"
        if nestedType != nil {
            innerObservation.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
            innerObservation.textColor = .secondaryLabel
            innerObservation.numberOfLines = 0
            innerObservation.accessibilityIdentifier = "nested.observation.\(index)"
            addSubview(innerObservation)
        } else {
            scroll.accessibilityIdentifier = "list.vertical.\(index)"
            scroll.alwaysBounceVertical = true
            addSubview(scroll)
            stack.axis = .vertical
            stack.spacing = 16
            scroll.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
                stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
                stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
                stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
            ])
            let heading = UILabel()
            heading.text = name
            heading.font = .preferredFont(forTextStyle: .title2)
            heading.accessibilityIdentifier = "page.heading.\(index)"
            stack.addArrangedSubview(heading)
            for number in 1...12 {
                let row = UILabel()
                row.numberOfLines = 2
                row.text = String(format: "%02d   %@ collection\n       Saved locally · ready to explore", number, name)
                row.font = .preferredFont(forTextStyle: .subheadline)
                row.textColor = .secondaryLabel
                stack.addArrangedSubview(row)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        installNestedIfHosted()
        scroll.frame = bounds
        innerSegmented?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 48)
        innerObservation.frame = CGRect(x: 12, y: 49, width: bounds.width - 24, height: 100)
        innerContainer?.frame = CGRect(x: 0, y: 152, width: bounds.width, height: max(0, bounds.height - 152))
        updateInnerObservation()
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        installNestedIfHosted()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        installNestedIfHosted()
    }

    /// The library attaches its child controller in willMove(toSuperview:), so wait for an owner.
    private func installNestedIfHosted() {
        guard innerContainer == nil, let nestedType else { return }
        var responder: UIResponder? = next
        var host: UIViewController?
        while let current = responder {
            if let controller = current as? UIViewController, controller.parent != nil || controller.viewIfLoaded?.window != nil {
                host = controller
                break
            }
            responder = current.next
        }
        guard let host else { return }
        innerHostController = host
        let source = JXSegmentedTitleDataSource()
        source.titles = ["Latest", "Popular", "Archive"]
        source.titleNormalColor = .secondaryLabel
        source.titleSelectedColor = .systemTeal
        let segmented = JXSegmentedView()
        segmented.accessibilityIdentifier = "nested.tabs.\(index)"
        segmented.dataSource = source
        segmented.delegate = self
        let line = JXSegmentedIndicatorLineView()
        line.indicatorColor = .systemTeal
        segmented.indicators = [line]
        let container = JXSegmentedListContainerView(dataSource: self, type: nestedType)
        container.listCellBackgroundColor = .secondarySystemGroupedBackground
        container.scrollView.accessibilityIdentifier = "nested.paging.\(index)"
        // Assign first to prevent reentrant layout from attempting another installation.
        innerSource = source
        innerSegmented = segmented
        innerContainer = container
        addSubview(segmented)
        addSubview(container)
        embeddedController = host.children.first(where: { $0.viewIfLoaded?.isDescendant(of: container) == true })
        segmented.listContainer = container
        LabFactory.applyMotion(to: segmented, source: source)
        segmented.reloadData()
        LabFactory.applyMotion(to: segmented, source: source)
        if let outerPending { beginEmbeddedAppearance(outerPending) }
        else if outerVisible { beginEmbeddedAppearance(true); endEmbeddedAppearance(true) }
        setNeedsLayout()
        updateInnerObservation()
    }

    private func updateInnerObservation() {
        guard let innerSegmented, let innerContainer else { return }
        let contained = innerHostController?.children.contains(where: { $0.viewIfLoaded?.isDescendant(of: innerContainer) == true }) == true
        let didAppear = innerEvents.filter { $0.hasPrefix("didAppear:") }.count
        let didDisappear = innerEvents.filter { $0.hasPrefix("didDisappear:") }.count
        let willAppear = innerEvents.filter { $0.hasPrefix("willAppear:") }.count
        let willDisappear = innerEvents.filter { $0.hasPrefix("willDisappear:") }.count
        let durations = innerSegmented.indicators.compactMap { ($0 as? JXSegmentedIndicatorBaseView)?.scrollAnimationDuration }.map { String(format: "%.2f", $0) }.joined(separator: ",")
        innerObservation.text = "Inner selected=\(innerSegmented.selectedIndex) callbacks=\(innerCallbacks) contained=\(contained)\ninnerWillAppear=\(willAppear) innerDidAppear=\(didAppear) innerWillDisappear=\(willDisappear) innerDidDisappear=\(didDisappear) lastInner=\(innerEvents.last ?? "none")\ncontentAnimation=\(innerSegmented.isContentScrollViewClickTransitionAnimationEnabled) selectedAnimation=\(innerSource?.isSelectedAnimable ?? false) widthAnimation=\(innerSource?.isItemWidthZoomAnimable ?? false) indicatorDurations=[\(durations)]"
    }

    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        innerCallbacks += 1
        updateInnerObservation()
    }
    func listView() -> UIView { self }
    // The outer library controller disables automatic appearance forwarding. Pair UIKit
    // transitions explicitly so its UIView-backed pages still propagate to embedded children.
    func listWillAppear() {
        outerPending = true
        beginEmbeddedAppearance(true)
        lifecycle("willAppear:\(index)")
    }
    func listDidAppear() {
        outerVisible = true
        outerPending = nil
        endEmbeddedAppearance(true)
        lifecycle("didAppear:\(index)")
    }
    func listWillDisappear() {
        outerPending = false
        beginEmbeddedAppearance(false)
        lifecycle("willDisappear:\(index)")
    }
    func listDidDisappear() {
        outerVisible = false
        outerPending = nil
        endEmbeddedAppearance(false)
        lifecycle("didDisappear:\(index)")
    }

    private func beginEmbeddedAppearance(_ appearing: Bool) {
        guard let embeddedController, embeddedController.parent != nil else { return }
        if embeddedPending == appearing { return }
        if let pending = embeddedPending {
            embeddedController.endAppearanceTransition()
            embeddedVisible = pending
            embeddedPending = nil
        }
        guard embeddedVisible != appearing else { return }
        embeddedController.beginAppearanceTransition(appearing, animated: false)
        embeddedPending = appearing
    }

    private func endEmbeddedAppearance(_ appearing: Bool) {
        guard let embeddedController, embeddedController.parent != nil else { return }
        if embeddedPending == nil, embeddedVisible != appearing { beginEmbeddedAppearance(appearing) }
        guard embeddedPending == appearing else { return }
        embeddedController.endAppearanceTransition()
        embeddedPending = nil
        embeddedVisible = appearing
        updateInnerObservation()
    }
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int { 3 }
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> any JXSegmentedListContainerViewListDelegate {
        PageList(index: index, name: ["Latest", "Popular", "Archive"][index]) { [weak self] event in
            self?.innerEvents.append(event)
            self?.updateInnerObservation()
        }
    }
}
