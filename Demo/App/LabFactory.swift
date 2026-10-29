import UIKit
import JXSegmentedView

@MainActor
enum LabFactory {
    static let initialTitles = ["Discover", "Following", "Saved", "For you"]
    static let symbols = ["sparkles", "person.2.fill", "bookmark.fill", "heart.fill"]

    static func dataSource(route: String, preset: Int, titles: [String], configuration: PerItemTypography) -> JXSegmentedBaseDataSource {
        let source: JXSegmentedBaseDataSource
        switch route {
        case "attributed":
            let attributed = JXSegmentedTitleAttributeDataSource()
            attributed.attributedTitles = titles.enumerated().map { index, title in
                NSAttributedString(string: "\(title)\n\(index + 1) collections", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel])
            }
            if preset == 1 {
                attributed.selectedAttributedTitles = titles.map { NSAttributedString(string: "★ \($0)", attributes: [.font: UIFont.boldSystemFont(ofSize: 19), .foregroundColor: UIColor.systemIndigo]) }
            }
            if preset == 2 { attributed.widthForTitleClosure = { text in max(110, CGFloat(text.length) * 5) } }
            source = attributed
        case "gradient":
            let gradient = JXSegmentedTitleGradientDataSource()
            gradient.titleNormalGradientColors = [UIColor.secondaryLabel.cgColor, UIColor.tertiaryLabel.cgColor]
            gradient.titleSelectedGradientColors = [UIColor.systemIndigo.cgColor, UIColor.systemPink.cgColor, UIColor.systemOrange.cgColor]
            gradient.titleGradientEndPoint = preset == 0 ? CGPoint(x: 1, y: 0) : CGPoint(x: 0, y: 1)
            source = gradient
        case "images":
            let image = JXSegmentedTitleImageDataSource()
            let layouts: [JXSegmentedTitleImageType] = [.topImage, .leftImage, .bottomImage, .rightImage, .onlyImage, .onlyTitle, .backgroundImage]
            image.titleImageType = layouts[preset]
            image.normalImageInfos = titles.indices.map { ["sparkle", "person.2", "bookmark", "heart"][$0 % 4] }
            image.selectedImageInfos = titles.indices.map { symbols[$0 % symbols.count] }
            image.imageSize = preset == 6 ? CGSize(width: 80, height: 40) : CGSize(width: 22, height: 22)
            image.loadImageClosure = { view, name in
                view.image = preset == 6 ? pillImage() : UIImage(systemName: name)
                view.tintColor = .systemIndigo
            }
            image.isImageZoomEnabled = true
            source = image
        case "title-or-image":
            let image = JXSegmentedTitleOrImageDataSource()
            image.selectedImageInfos = titles.indices.map { preset == 1 && $0.isMultiple(of: 2) ? nil : symbols[$0 % symbols.count] }
            image.loadImageClosure = { view, name in view.image = UIImage(systemName: name); view.tintColor = .systemIndigo }
            source = image
        case "badges":
            if preset == 0 {
                let dot = JXSegmentedDotDataSource()
                dot.dotStates = titles.indices.map { $0.isMultiple(of: 2) }
                dot.dotColor = .systemOrange
                dot.dotSize = CGSize(width: 7, height: 7)
                dot.dotOffset = CGPoint(x: 3, y: -3)
                source = dot
            } else {
                let number = JXSegmentedNumberDataSource()
                number.numbers = titles.indices.map { [0, 3, 42, 108][$0 % 4] }
                number.numberBackgroundColor = .systemIndigo
                if preset == 2 { number.numberStringFormatterClosure = { $0 > 99 ? "99+" : String($0) } }
                source = number
            }
        case "custom":
            source = CapsuleDataSource()
        default:
            source = JXSegmentedTitleDataSource()
        }
        source.itemWidthIncrement = 16
        source.isItemSpacingAverageEnabled = false
        source.itemSpacing = 18
        source.isSelectedAnimable = !DemoEnvironment.shared.reduceMotion && !UIAccessibility.isReduceMotionEnabled
        source.selectedAnimationDuration = 0.22
        if let title = source as? JXSegmentedTitleDataSource {
            title.titles = titles
            title.titleNormalColor = .secondaryLabel
            title.titleSelectedColor = .systemIndigo
            title.titleNormalFont = .systemFont(ofSize: 16, weight: .medium)
            title.isTitleColorGradientEnabled = true
            if route == "titles" { title.isTitleColorGradientEnabled = preset == 1; title.isSelectedAnimable = preset == 2 && !DemoEnvironment.shared.reduceMotion }
            if route == "layout" {
                switch preset {
                case 0: source.itemWidthIncrement = 0
                case 1: source.itemWidth = 120
                case 2: title.widthForTitleClosure = { CGFloat($0.count) * 12 + 24 }
                case 3: source.itemWidthIncrement = 56
                case 4: source.isItemSpacingAverageEnabled = true; source.itemSpacing = 4
                case 5: source.itemSpacing = 40
                case 7: source.itemWidth = 130; title.widthForTitleClosure = { _ in 60 }
                default: break
                }
            }
            if route == "typography" {
                switch preset {
                case 0: title.configuration = configuration
                case 1: title.titles = ["Discover\nnew ideas", "Your\ncommunity", "Saved\ncollections", "Just\nfor you"]; title.titleNumberOfLines = 2
                case 2: title.titles = ["An exceptionally long discovery title", "Following", "Saved collections and favorite moments", "For you"]
                case 3: title.isTitleMaskEnabled = true
                case 4: title.isTitleStrokeWidthEnabled = true; title.titleSelectedStrokeWidth = -4
                case 5: title.isTitleZoomEnabled = true; title.titleSelectedZoomScale = 1.3
                case 6: title.isItemWidthZoomEnabled = true; title.itemWidthSelectedZoomScale = 1.5
                case 7: title.isItemTransitionEnabled = false
                default: break
                }
            }
        }
        if DemoEnvironment.shared.reduceMotion || UIAccessibility.isReduceMotionEnabled { source.isSelectedAnimable = false; source.isItemWidthZoomAnimable = false }
        return source
    }

    static var reducesMotion: Bool { DemoEnvironment.shared.reduceMotion || UIAccessibility.isReduceMotionEnabled }

    /// Apply after every preset is built, including custom and composite indicator presets.
    static func applyMotion(to segmented: JXSegmentedView, source: JXSegmentedBaseDataSource) {
        guard reducesMotion else { return }
        source.isSelectedAnimable = false
        source.isItemWidthZoomAnimable = false
        source.selectedAnimationDuration = 0
        segmented.isContentScrollViewClickTransitionAnimationEnabled = false
        for indicator in segmented.indicators {
            (indicator as? JXSegmentedIndicatorBaseView)?.scrollAnimationDuration = 0
        }
    }

    static func indicators(route: String, preset: Int, count: Int) -> [JXSegmentedIndicatorProtocol] {
        let indicators = makeIndicators(route: route, preset: preset, count: count)
        if reducesMotion {
            for indicator in indicators { (indicator as? JXSegmentedIndicatorBaseView)?.scrollAnimationDuration = 0 }
        }
        return indicators
    }

    private static func makeIndicators(route: String, preset: Int, count: Int) -> [JXSegmentedIndicatorProtocol] {
        if route == "images" && preset == 6 { return [] }
        if route == "custom" && preset == 1 { return [BracketIndicator()] }
        if route == "typography" && preset == 3 {
            let background = JXSegmentedIndicatorBackgroundView()
            background.indicatorColor = .systemIndigo
            return [background]
        }
        let type = route == "indicators" ? preset : 0
        let indicator: JXSegmentedIndicatorBaseView
        switch type {
        case 3: indicator = JXSegmentedIndicatorTriangleView()
        case 4: indicator = JXSegmentedIndicatorBackgroundView(); indicator.indicatorColor = UIColor.systemIndigo.withAlphaComponent(0.15)
        case 5:
            let gradient = JXSegmentedIndicatorGradientView()
            gradient.gradientColors = [UIColor.systemIndigo.withAlphaComponent(0.25).cgColor, UIColor.systemPink.withAlphaComponent(0.2).cgColor]
            indicator = gradient
        case 6:
            let gradient = JXSegmentedIndicatorGradientLineView()
            gradient.colors = [.systemIndigo, .systemPink, .systemOrange]
            indicator = gradient
        case 7:
            let rainbow = JXSegmentedIndicatorRainbowLineView()
            rainbow.indicatorColors = (0..<count).map { [UIColor.systemIndigo, .systemPink, .systemOrange, .systemTeal][$0 % 4] }
            indicator = rainbow
        case 8: indicator = JXSegmentedIndicatorDoubleLineView()
        case 9: indicator = JXSegmentedIndicatorDotLineView()
        case 10:
            let image = JXSegmentedIndicatorImageView()
            image.image = UIImage(systemName: "arrowtriangle.up.fill")?.withTintColor(.systemIndigo, renderingMode: .alwaysOriginal)
            image.indicatorWidth = 14; image.indicatorHeight = 10
            indicator = image
        case 11: return []
        case 12:
            let background = JXSegmentedIndicatorBackgroundView()
            background.indicatorColor = UIColor.systemIndigo.withAlphaComponent(0.13)
            let line = JXSegmentedIndicatorLineView()
            line.indicatorColor = .systemIndigo
            line.isIndicatorConvertToItemFrameEnabled = false
            return [background, line]
        default:
            let line = JXSegmentedIndicatorLineView()
            line.lineStyle = type == 1 ? .lengthen : (type == 2 ? .lengthenOffset : .normal)
            indicator = line
        }
        if type != 4 && type != 5 { indicator.indicatorColor = .systemIndigo }
        if route == "layout" && preset == 7 { indicator.isIndicatorWidthSameAsItemContent = true }
        if type == 13 { indicator.indicatorPosition = .top; indicator.indicatorWidth = 30; indicator.indicatorHeight = 5; indicator.verticalOffset = 3 }
        if type == 14 { indicator.isIndicatorWidthSameAsItemContent = true; indicator.indicatorWidthIncrement = 12; indicator.verticalOffset = 4; indicator.indicatorCornerRadius = 2 }
        if type == 15 { indicator.isScrollEnabled = false }
        if DemoEnvironment.shared.reduceMotion || UIAccessibility.isReduceMotionEnabled { indicator.scrollAnimationDuration = 0 }
        return [indicator]
    }

    static func pillImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 80, height: 40)).image { context in
            UIColor.systemIndigo.withAlphaComponent(0.12).setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 80, height: 40), cornerRadius: 14).fill()
            context.cgContext.setStrokeColor(UIColor.systemIndigo.cgColor)
            context.cgContext.stroke(CGRect(x: 1, y: 1, width: 78, height: 38))
        }
    }
}

@MainActor
final class PerItemTypography: NSObject, JXSegmentedTitleDynamicConfiguration {
    func titleNumberOfLines(at index: Int) -> Int { 1 }
    func titleNormalColor(at index: Int) -> UIColor { index.isMultiple(of: 2) ? .secondaryLabel : .systemTeal }
    func titleSelectedColor(at index: Int) -> UIColor { .systemIndigo }
    func titleNormalFont(at index: Int) -> UIFont { .systemFont(ofSize: CGFloat(13 + index * 2), weight: .regular) }
    func titleSelectedFont(at index: Int) -> UIFont? { .systemFont(ofSize: CGFloat(18 + index * 2), weight: .bold) }
}
