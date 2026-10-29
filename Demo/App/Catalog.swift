import UIKit

struct CatalogRoute: Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let presets: [String]

    static let all: [CatalogRoute] = [
        .init(id: "titles", title: "Titles", subtitle: "Color interpolation and selection", symbol: "textformat", presets: ["Classic", "Color transition", "Click animation"]),
        .init(id: "attributed", title: "Attributed titles", subtitle: "Rich text, selected text and measured widths", symbol: "textformat.abc", presets: ["Rich text", "Selected text", "Width closure"]),
        .init(id: "gradient", title: "Gradient titles", subtitle: "Three color text with horizontal and vertical ramps", symbol: "paintpalette", presets: ["Horizontal", "Vertical"]),
        .init(id: "images", title: "Title + image", subtitle: "Seven layouts, local symbols and image zoom", symbol: "photo.on.rectangle", presets: ["Top", "Left", "Bottom", "Right", "Image only", "Title only", "Background"]),
        .init(id: "title-or-image", title: "Title or image", subtitle: "Selected symbol replaces text", symbol: "arrow.triangle.2.circlepath", presets: ["Replace all", "Mixed replacements"]),
        .init(id: "badges", title: "Dots & numbers", subtitle: "Dot offsets, counts and custom formatting", symbol: "app.badge", presets: ["Dots", "Numbers", "Formatted numbers"]),
        .init(id: "indicators", title: "Indicators", subtitle: "Every built-in indicator, no indicator and combinations", symbol: "underline", presets: ["Line", "Lengthen", "Lengthen offset", "Triangle", "Background", "Gradient background", "Gradient line", "Rainbow", "Double line", "Dot line", "Image", "None", "Multiple", "Top / fixed", "Content width / inset", "No scroll transition"]),
        .init(id: "layout", title: "Widths & spacing", subtitle: "Natural, fixed, measured and extra item widths", symbol: "arrow.left.and.right", presets: ["Natural", "Fixed", "Width closure", "Increment", "Average spacing", "Fixed spacing", "Edge insets", "Item content width"]),
        .init(id: "typography", title: "Typography & transitions", subtitle: "Per-item fonts, multiline, long text, mask, stroke and zoom", symbol: "textformat.size", presets: ["Per-item fonts", "Multiline", "Long titles", "Mask", "Stroke", "Title zoom", "Width zoom", "No transition"]),
        .init(id: "containers", title: "List containers", subtitle: "Scroll and collection containers, direct paging, lazy load", symbol: "rectangle.split.3x1", presets: ["Scroll container", "Collection container", "Direct scroll view", "Start on third", "Lazy threshold"]),
        .init(id: "nested", title: "Nested lists", subtitle: "Independent inner segmented views and vertical lists", symbol: "square.stack.3d.up", presets: ["Nested horizontal", "Nested collection"]),
        .init(id: "navigation", title: "Navigation title", subtitle: "Segmented control in a native navigation bar", symbol: "rectangle.topthird.inset.filled", presets: ["Title view", "Compact title view"]),
        .init(id: "custom", title: "Custom extensions", subtitle: "Public cell, item model, data source and indicator hooks", symbol: "puzzlepiece.extension", presets: ["Custom capsule", "Custom indicator"]),
        .init(id: "dynamic", title: "Dynamic data & lifecycle", subtitle: "Empty / restore, mutations, reload and scroll replacement", symbol: "arrow.clockwise", presets: ["Mutable titles", "Animated selection"])
    ]
}

@MainActor
final class DemoEnvironment {
    static let shared = DemoEnvironment()
    var style: UIUserInterfaceStyle = .unspecified
    var rtl = false
    var reduceMotion = false

    func apply(to controller: UIViewController) {
        controller.overrideUserInterfaceStyle = style
        controller.view.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    }

    func menu(changed: @escaping @MainActor () -> Void) -> UIMenu {
        UIMenu(title: "Environment", children: [
            UIMenu(title: "Appearance", children: [("System", UIUserInterfaceStyle.unspecified), ("Light", .light), ("Dark", .dark)].map { title, value in
                UIAction(title: title, state: style == value ? .on : .off) { [weak self] _ in self?.style = value; changed() }
            }),
            UIAction(title: "Right to left", state: rtl ? .on : .off) { [weak self] _ in self?.rtl.toggle(); changed() },
            UIAction(title: "Reduce motion (demo)", state: reduceMotion ? .on : .off) { [weak self] _ in self?.reduceMotion.toggle(); changed() }
        ])
    }
}

@MainActor
final class CatalogViewController: UITableViewController {
    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Segmented Lab"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.accessibilityIdentifier = "catalog"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "route")
        refreshEnvironment()
    }

    private func refreshEnvironment() {
        DemoEnvironment.shared.apply(to: self)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), menu: DemoEnvironment.shared.menu { [weak self] in self?.refreshEnvironment() })
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "environment"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { CatalogRoute.all.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "UIKit • Swift 6 • Offline" }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { "Choose a lab, change its preset, then tap a tab or swipe a page. Live observations report the library’s selection and list lifecycle." }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let route = CatalogRoute.all[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "route", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = route.title
        content.secondaryText = route.subtitle
        content.image = UIImage(systemName: route.symbol)
        content.imageProperties.tintColor = .systemIndigo
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "route.\(route.id)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(LabViewController(route: CatalogRoute.all[indexPath.row]), animated: true)
    }
}
