import UIKit
import JXSegmentedView

@MainActor
final class LabViewController: UIViewController, JXSegmentedViewDelegate, JXSegmentedListContainerViewDataSource {
    let route: CatalogRoute
    private var preset = 0
    private var titles = LabFactory.initialTitles
    private let typography = PerItemTypography()
    private var source: JXSegmentedBaseDataSource?
    private var segmented = JXSegmentedView()
    private var container: JXSegmentedListContainerView?
    private var directScroll: ProbeTrackingScrollView?
    private var pagingOffsetObservation: NSKeyValueObservation?
    private var observesWhileVisible = false
    private var idleRefreshGeneration = 0
    private var idleRefreshScheduled = false
    private var idleRefreshAttempts = 0
    private var retiredNestedDisappearDelta = 0
    private var retiredHostAttached = false
    private var directPages: [PageList] = []
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let segmentHost = UIView()
    private let pageHost = UIView()
    private let status = UILabel()
    private let presetLabel = UILabel()
    private let presetButton = UIButton(type: .system)
    private var clicks = 0
    private var selections = 0
    private var swipes = 0
    private var progressEvents = 0
    private var lifecycleEvents = 0
    private var lastEvent = "No callback yet"
    private var reloads = 0
    private var replacements = 0
    private var isRebuilding = false
    private var pageHeight: NSLayoutConstraint?
    private var deniedIndex: Int?
    private var abandonedScroll: ProbeTrackingScrollView?

    init(route: CatalogRoute) { self.route = route; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = route.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "lab.\(route.id)"
        scroll.accessibilityIdentifier = "lab.scroll"
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
        let description = UILabel()
        description.text = route.subtitle
        description.font = .preferredFont(forTextStyle: .subheadline)
        description.textColor = .secondaryLabel
        description.numberOfLines = 0
        stack.addArrangedSubview(description)
        let presetRow = UIStackView()
        presetRow.spacing = 12
        presetLabel.font = .preferredFont(forTextStyle: .headline)
        presetLabel.numberOfLines = 2
        presetLabel.accessibilityIdentifier = "preset.name"
        presetRow.addArrangedSubview(presetLabel)
        presetButton.setTitle("Next preset", for: .normal)
        presetButton.accessibilityIdentifier = "preset.next"
        presetButton.setContentHuggingPriority(.required, for: .horizontal)
        presetButton.addAction(UIAction { [weak self] _ in self?.nextPreset() }, for: .touchUpInside)
        presetRow.addArrangedSubview(presetButton)
        stack.addArrangedSubview(presetRow)
        segmentHost.backgroundColor = .secondarySystemGroupedBackground
        segmentHost.layer.cornerRadius = 16
        segmentHost.clipsToBounds = true
        segmentHost.heightAnchor.constraint(equalToConstant: 78).isActive = true
        stack.addArrangedSubview(segmentHost)
        let actions = UIStackView()
        actions.distribution = .fillEqually
        actions.spacing = 12
        actions.addArrangedSubview(button("Previous", id: "selection.previous") { [weak self] in self?.select(delta: -1) })
        actions.addArrangedSubview(button("Next tab", id: "selection.next") { [weak self] in self?.select(delta: 1) })
        stack.addArrangedSubview(actions)
        status.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        status.textColor = .secondaryLabel
        status.numberOfLines = 0
        status.accessibilityIdentifier = "observation"
        status.isAccessibilityElement = true
        pageHeight = pageHost.heightAnchor.constraint(equalToConstant: route.id == "nested" ? 330 : 230)
        pageHeight?.isActive = true
        stack.addArrangedSubview(pageHost)
        stack.addArrangedSubview(status)
        if route.id == "dynamic" { addDynamicControls() }
        let note = UILabel()
        note.text = "Tap a tab or swipe horizontally in the page. Vertical collections scroll independently. Observations above are read from public library state and delegate callbacks."
        note.font = .preferredFont(forTextStyle: .footnote)
        note.textColor = .secondaryLabel
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
        refreshEnvironment()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observesWhileVisible = true
        idleRefreshAttempts = 0
        updateObservation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        observesWhileVisible = false
        cancelIdleRefresh()
        super.viewWillDisappear(animated)
    }

    private func cancelIdleRefresh() {
        idleRefreshGeneration += 1
        idleRefreshScheduled = false
        idleRefreshAttempts = 0
    }

    /// UIKit may finish decelerating without another offset notification. Refresh until idle,
    /// without replacing the list container's delegate or retaining the screen after dismissal.
    private func refreshWhenIdleIfNeeded(settled: Bool) {
        guard observesWhileVisible, !settled, !titles.isEmpty, viewIfLoaded?.window != nil,
              !idleRefreshScheduled, idleRefreshAttempts < 120 else { return }
        idleRefreshScheduled = true
        let generation = idleRefreshGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, self.idleRefreshGeneration == generation else { return }
            self.idleRefreshScheduled = false
            self.idleRefreshAttempts += 1
            self.updateObservation()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if route.id != "navigation" { segmented.frame = segmentHost.bounds.insetBy(dx: 4, dy: 4) }
        container?.frame = pageHost.bounds
        if let directScroll {
            let widthChanged = directScroll.bounds.width != pageHost.bounds.width
            directScroll.frame = pageHost.bounds
            directScroll.contentSize = CGSize(width: directScroll.bounds.width * CGFloat(titles.count), height: directScroll.bounds.height)
            for (index, page) in directPages.enumerated() {
                page.frame = CGRect(x: CGFloat(index) * directScroll.bounds.width, y: 0, width: directScroll.bounds.width, height: directScroll.bounds.height)
            }
            if widthChanged { directScroll.contentOffset.x = CGFloat(segmented.selectedIndex) * directScroll.bounds.width }
        }
        updateObservation()
    }

    private func refreshEnvironment() {
        DemoEnvironment.shared.apply(to: self)
        // The library consults UIAppearance when constructing its RTL-compatible cells/containers.
        UIView.appearance().semanticContentAttribute = DemoEnvironment.shared.rtl ? .forceRightToLeft : .forceLeftToRight
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), menu: DemoEnvironment.shared.menu { [weak self] in self?.refreshEnvironment() })
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "environment"
        rebuild()
    }

    private func nextPreset() { preset = (preset + 1) % route.presets.count; rebuild() }

    private func rebuild() {
        cancelIdleRefresh()
        isRebuilding = true
        segmented.delegate = nil
        pagingOffsetObservation = nil
        segmented.contentScrollView = nil
        segmented.listContainer = nil
        navigationItem.titleView = nil
        segmented.removeFromSuperview()
        if let container { detach(container) }
        directScroll?.removeFromSuperview()
        directScroll = nil
        directPages = []
        container = nil
        abandonedScroll = nil
        titles = LabFactory.initialTitles
        source = LabFactory.dataSource(route: route.id, preset: preset, titles: titles, configuration: typography)
        segmented = JXSegmentedView()
        segmented.accessibilityIdentifier = "segmented"
        segmented.collectionView.accessibilityIdentifier = "tabs"
        segmented.dataSource = source
        segmented.delegate = self
        segmented.isContentScrollViewClickTransitionAnimationEnabled = !DemoEnvironment.shared.reduceMotion && !UIAccessibility.isReduceMotionEnabled
        segmented.indicators = LabFactory.indicators(route: route.id, preset: preset, count: titles.count)
        if route.id == "layout" && preset == 6 { segmented.contentEdgeInsetLeft = 44; segmented.contentEdgeInsetRight = 66 }
        if route.id == "containers" && preset == 3 { segmented.defaultSelectedIndex = 2 }
        if route.id == "navigation" {
            segmented.frame = CGRect(x: 0, y: 0, width: preset == 0 ? 270 : 210, height: 38)
            if let source { source.itemSpacing = 6; source.itemWidthIncrement = 4; source.isItemSpacingAverageEnabled = true }
            navigationItem.titleView = segmented
            let hint = UILabel(frame: segmentHost.bounds)
            hint.text = "Tabs are in the navigation bar ↑"
            hint.textAlignment = .center
            hint.font = .preferredFont(forTextStyle: .subheadline)
            hint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            segmentHost.subviews.forEach { $0.removeFromSuperview() }
            segmentHost.addSubview(hint)
        } else {
            segmentHost.subviews.forEach { $0.removeFromSuperview() }
            segmentHost.addSubview(segmented)
        }
        if (route.id == "containers" && preset == 2) || route.id == "dynamic" { installDirectScroll() }
        else {
            let type: JXSegmentedListContainerType = (route.id == "containers" && preset == 1) || (route.id == "nested" && preset == 1) ? .collectionView : .scrollView
            let container = JXSegmentedListContainerView(dataSource: self, type: type)
            container.listCellBackgroundColor = .secondarySystemGroupedBackground
            if route.id == "containers" && preset == 4 { container.initListPercent = 0.8 }
            container.scrollView.accessibilityIdentifier = "paging"
            self.container = container
            pageHost.addSubview(container)
            segmented.listContainer = container
        }
        if route.id == "dynamic", let source { source.isSelectedAnimable = preset == 1 && !DemoEnvironment.shared.reduceMotion }
        presetLabel.text = "\(preset + 1)/\(route.presets.count)  \(route.presets[preset])"
        presetLabel.accessibilityValue = route.presets[preset]
        if let source { LabFactory.applyMotion(to: segmented, source: source) }
        segmented.reloadData()
        if let source { LabFactory.applyMotion(to: segmented, source: source) }
        observePagingOffset()
        isRebuilding = false
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateObservation()
    }

    private func detach(_ container: JXSegmentedListContainerView) {
        let pages = container.validListDict.values.compactMap { $0 as? PageList }
        let before = pages.reduce(0) { $0 + $1.innerDidDisappearCount }
        let hosts = children.filter { $0.view.isDescendant(of: container) }
        for child in hosts {
            child.beginAppearanceTransition(false, animated: false)
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.endAppearanceTransition()
            child.removeFromParent()
        }
        retiredNestedDisappearDelta = pages.reduce(0) { $0 + $1.innerDidDisappearCount } - before
        retiredHostAttached = hosts.contains { $0.parent != nil }
        container.removeFromSuperview()
    }

    private func installDirectScroll() {
        directScroll?.removeFromSuperview()
        pagingOffsetObservation = nil
        let paging = ProbeTrackingScrollView()
        paging.isPagingEnabled = true
        paging.bounces = false
        paging.contentInsetAdjustmentBehavior = .never
        paging.showsHorizontalScrollIndicator = false
        paging.accessibilityIdentifier = "paging"
        pageHost.addSubview(paging)
        directPages = titles.enumerated().map { index, title in
            let page = PageList(index: index, name: title, lifecycle: { _ in })
            paging.addSubview(page)
            return page
        }
        directScroll = paging
        segmented.contentScrollView = paging
        observePagingOffset()
    }

    private func button(_ title: String, id: String, action: @escaping @MainActor () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.configuration = .tinted()
        button.configuration?.title = title
        button.accessibilityIdentifier = id
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func addDynamicControls() {
        let actions: [(String, String, @MainActor () -> Void)] = [
            ("Empty / restore", "data.empty", { [weak self] in self?.mutate(.empty) }),
            ("Insert", "data.insert", { [weak self] in self?.mutate(.insert) }),
            ("Delete", "data.delete", { [weak self] in self?.mutate(.delete) }),
            ("Reorder", "data.reorder", { [weak self] in self?.mutate(.reorder) }),
            ("Reload item", "data.item", { [weak self] in self?.mutate(.item) }),
            ("Reload all", "data.reload", { [weak self] in self?.mutate(.reload) }),
            ("Replace scroll", "data.replace", { [weak self] in self?.replaceScroll() }),
            ("Rapid select", "data.rapid", { [weak self] in self?.rapidSelect() }),
            ("Toggle click gate", "data.gate", { [weak self] in self?.deniedIndex = self?.deniedIndex == nil ? 1 : nil; self?.updateObservation() }),
            ("Move old scroll", "data.old-scroll", { [weak self] in self?.probeOldScroll() })
        ]
        for start in stride(from: 0, to: actions.count, by: 2) {
            let row = UIStackView()
            row.distribution = .fillEqually
            row.spacing = 8
            for (title, id, action) in actions[start..<min(start + 2, actions.count)] { row.addArrangedSubview(button(title, id: id, action: action)) }
            stack.addArrangedSubview(row)
        }
    }

    private enum Mutation { case empty, insert, delete, reorder, item, reload }
    private func mutate(_ mutation: Mutation) {
        guard let source = source as? JXSegmentedTitleDataSource else { return }
        switch mutation {
        case .empty: titles = titles.isEmpty ? LabFactory.initialTitles : []
        case .insert: titles.append("New \(titles.count + 1)")
        case .delete: if !titles.isEmpty { titles.remove(at: min(segmented.selectedIndex, titles.count - 1)) }
        case .reorder: titles.reverse()
        case .item:
            guard !titles.isEmpty else { return }
            let index = min(segmented.selectedIndex, titles.count - 1)
            titles[index] = titles[index].hasSuffix(" ★") ? titles[index].replacingOccurrences(of: " ★", with: "") : titles[index] + " ★"
            source.titles = titles
            segmented.reloadItem(at: index)
            let replacement = PageList(index: index, name: titles[index], lifecycle: { _ in })
            replacement.frame = directPages[index].frame
            directPages[index].removeFromSuperview()
            directScroll?.addSubview(replacement)
            directPages[index] = replacement
            reloads += 1
            updateObservation()
            return
        case .reload: break
        }
        source.titles = titles
        installDirectScroll()
        segmented.reloadData()
        reloads += 1
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateObservation()
    }
    private func replaceScroll() {
        abandonedScroll = directScroll
        installDirectScroll()
        replacements += 1
        view.setNeedsLayout()
        view.layoutIfNeeded()
        directScroll?.contentOffset.x = CGFloat(segmented.selectedIndex) * (directScroll?.bounds.width ?? 0)
        updateObservation()
    }
    private func probeOldScroll() {
        guard let abandonedScroll, !titles.isEmpty else { return }
        abandonedScroll.forceTrackingForProbe = true
        // A stale observer would process this as a user-driven page change.
        let target = (segmented.selectedIndex + 1) % titles.count
        abandonedScroll.contentOffset.x = CGFloat(target) * abandonedScroll.bounds.width
        updateObservation()
    }

    private func observePagingOffset() {
        pagingOffsetObservation = segmented.contentScrollView?.observe(\.contentOffset, options: .new) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.idleRefreshAttempts = 0; self?.updateObservation() }
        }
    }

    private func rapidSelect() {
        guard !titles.isEmpty else { return }
        for index in [2, 0, 3, 1, 2] where index < titles.count { segmented.selectItemAt(index: index) }
        updateObservation()
    }
    private func select(delta: Int) {
        guard !titles.isEmpty else { return }
        segmented.selectItemAt(index: (segmented.selectedIndex + delta + titles.count) % titles.count)
        updateObservation()
    }

    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int { titles.count }
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> any JXSegmentedListContainerViewListDelegate {
        let nestedType: JXSegmentedListContainerType? = route.id == "nested" ? (preset == 0 ? .scrollView : .collectionView) : nil
        return PageList(index: index, name: titles[index], nestedType: nestedType) { [weak self] event in
            self?.lifecycleEvents += 1
            self?.lastEvent = event
            self?.updateObservation()
        }
    }
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) { selections += 1; lastEvent = "selected:\(index)"; updateObservation() }
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) { clicks += 1; lastEvent = "click:\(index)"; updateObservation() }
    func segmentedView(_ segmentedView: JXSegmentedView, didScrollSelectedItemAt index: Int) { swipes += 1; lastEvent = "scroll:\(index)"; updateObservation() }
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) { progressEvents += 1; updateObservation() }
    func segmentedView(_ segmentedView: JXSegmentedView, canClickItemAt index: Int) -> Bool { index != deniedIndex }

    private func displayTitle(at index: Int) -> String {
        guard let source, source.dataSource.indices.contains(index) else { return "empty" }
        if let model = source.dataSource[index] as? JXSegmentedTitleItemModel { return model.title ?? "" }
        if let model = source.dataSource[index] as? JXSegmentedTitleAttributeItemModel {
            return (model.isSelected ? (model.selectedAttributedTitle ?? model.attributedTitle) : model.attributedTitle)?.string ?? ""
        }
        return "item \(index)"
    }

    private func updateObservation() {
        guard isViewLoaded, !isRebuilding else { return }
        let count = segmented.collectionView.numberOfItems(inSection: 0)
        for cell in segmented.collectionView.visibleCells {
            guard let index = segmented.collectionView.indexPath(for: cell)?.item, index < titles.count else { continue }
            cell.isAccessibilityElement = true
            cell.accessibilityIdentifier = "tab.\(index)"
            cell.accessibilityLabel = displayTitle(at: index)
            cell.accessibilityTraits = segmented.selectedIndex == index ? [.button, .selected] : [.button]
        }
        let loaded = container?.validListDict.keys.sorted().map(String.init).joined(separator: ",") ?? directPages.map { String($0.index) }.joined(separator: ",")
        let geometry = segmented.indicators.map { String(format: "%.0fx%.0f", $0.frame.width, $0.frame.height) }.joined(separator: ",")
        let currentTitle = displayTitle(at: segmented.selectedIndex)
        let paging = segmented.contentScrollView
        let offsetPage = (paging?.bounds.width ?? 0) > 0 ? (paging?.contentOffset.x ?? 0) / (paging?.bounds.width ?? 1) : 0
        let visibleIndex = Int(offsetPage.rounded())
        let visibleTitle: String
        if let page = directPages.first(where: { $0.index == visibleIndex }) { visibleTitle = page.observedTitle }
        else if let page = container?.validListDict[visibleIndex] as? PageList { visibleTitle = page.observedTitle }
        else { visibleTitle = "empty" }
        let selectedModels = source?.dataSource.filter(\.isSelected).count ?? 0
        let settled = !titles.isEmpty && abs(offsetPage - CGFloat(segmented.selectedIndex)) < 0.001 && paging?.isDragging != true && paging?.isDecelerating != true
        let durations = segmented.indicators.compactMap { ($0 as? JXSegmentedIndicatorBaseView)?.scrollAnimationDuration }.map { String(format: "%.2f", $0) }.joined(separator: ",")
        let motion = "contentAnimation=\(segmented.isContentScrollViewClickTransitionAnimationEnabled) selectedAnimation=\(source?.isSelectedAnimable ?? false) widthAnimation=\(source?.isItemWidthZoomAnimable ?? false) indicatorDurations=[\(durations)]"
        let pageState = "offsetPage=\(String(format: "%.2f", offsetPage)) visibleTitle=\(visibleTitle) selectedModels=\(selectedModels) settled=\(settled) oldTracking=\(abandonedScroll?.isTracking ?? false) oldOffsetPage=\(String(format: "%.2f", (abandonedScroll?.contentOffset.x ?? 0) / max(1, abandonedScroll?.bounds.width ?? 1)))"
        let nestedState = route.id == "nested" ? (container?.validListDict.values.compactMap { $0 as? PageList }.sorted { $0.index < $1.index }.map(\.innerLifecycleSummary).joined(separator: " ") ?? "") : ""
        let text = "items=\(count) selected=\(segmented.selectedIndex) title=\(currentTitle)\nselectedCallbacks=\(selections) clicks=\(clicks) swipes=\(swipes) progress=\(progressEvents)\nloaded=[\(loaded)] lifecycle=\(lifecycleEvents) indicators=\(segmented.indicators.count) frames=[\(geometry)]\nreloads=\(reloads) replacements=\(replacements) gate=\(deniedIndex.map(String.init) ?? "off")\n\(pageState)\n\(nestedState) retiredNestedDisappearDelta=\(retiredNestedDisappearDelta) retiredHostAttached=\(retiredHostAttached)\n\(motion)\nlast=\(lastEvent) appearance=\(traitCollection.userInterfaceStyle == .dark ? "dark" : "light") rtl=\(segmented.segmentedViewShouldRTLLayout()) reduceMotion=\(DemoEnvironment.shared.reduceMotion || UIAccessibility.isReduceMotionEnabled)"
        if status.text != text { status.text = text; status.accessibilityValue = text }
        refreshWhenIdleIfNeeded(settled: settled)
    }
}

/// Tracking is forced only for the detached old-scroll probe, so stale KVO would be observable.
@MainActor
final class ProbeTrackingScrollView: UIScrollView {
    var forceTrackingForProbe = false
    override var isTracking: Bool { forceTrackingForProbe || super.isTracking }
}
