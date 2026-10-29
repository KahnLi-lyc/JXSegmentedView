import XCTest
import UIKit
@testable import JXSegmentedView

@MainActor
final class TitleRegressionTests: XCTestCase {
    private func model(selected: Bool = true) -> JXSegmentedTitleItemModel {
        let model = JXSegmentedTitleItemModel()
        model.title = "动态标题 العربية"
        model.isSelected = selected
        model.titleNormalColor = .black
        model.titleSelectedColor = .red
        model.titleCurrentColor = selected ? .red : .black
        return model
    }

    private func cell(_ model: JXSegmentedTitleItemModel) -> JXSegmentedTitleCell {
        let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
        cell.reloadData(itemModel: model, selectedType: .unknown)
        cell.layoutIfNeeded()
        return cell
    }

    func testSelectedTitleSurvivesPressAndCancel() {
        let model = model()
        let cell = cell(model)
        cell.isSelected = true
        cell.isHighlighted = true
        cell.isHighlighted = false
        XCTAssertEqual(cell.titleLabel.textColor, model.titleCurrentColor)
        XCTAssertEqual(model.titleCurrentColor, .red)
    }

    func testUnselectedPressDoesNotReplaceModelColor() {
        let model = model(selected: false)
        let cell = cell(model)
        cell.isHighlighted = true
        XCTAssertEqual(cell.titleLabel.textColor, model.titleCurrentColor)
        cell.isHighlighted = false
        XCTAssertEqual(cell.titleLabel.textColor, .black)
    }

    func testUIKitSelectionDoesNotOverrideScrollGradient() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["发现", "العربية"]
        source.isTitleColorGradientEnabled = true
        source.reloadData(selectedIndex: 0)
        let left = source.dataSource[0] as! JXSegmentedTitleItemModel
        let right = source.dataSource[1] as! JXSegmentedTitleItemModel
        source.refreshItemModel(JXSegmentedView(), leftItemModel: left, rightItemModel: right, percent: 0.4)
        for model in [left, right] {
            let cell = cell(model)
            let expected = model.titleCurrentColor
            cell.isSelected = true
            XCTAssertEqual(cell.titleLabel.textColor, expected)
            cell.isHighlighted = true
            cell.isHighlighted = false
            cell.isSelected = false
            XCTAssertEqual(cell.titleLabel.textColor, expected)
            XCTAssertEqual(model.titleCurrentColor, expected)
        }
    }

    func testMaskColorsAndLayersSurviveUIKitStates() {
        let model = model()
        model.isTitleMaskEnabled = true
        model.indicatorConvertToItemFrame = CGRect(x: 10, y: 0, width: 80, height: 44)
        let cell = cell(model)
        let titleMask = cell.titleLabel.layer.mask
        let topFrame = cell.maskTitleMaskLayer.frame
        cell.isHighlighted = true
        XCTAssertEqual(cell.titleLabel.textColor, model.titleNormalColor)
        cell.isSelected = true
        XCTAssertEqual(cell.titleLabel.textColor, model.titleNormalColor)
        cell.isHighlighted = false
        XCTAssertEqual(cell.titleLabel.textColor, model.titleNormalColor)
        XCTAssertEqual(cell.maskTitleLabel.textColor, model.titleSelectedColor)
        XCTAssertTrue(cell.titleLabel.layer.mask === titleMask)
        XCTAssertTrue(cell.maskTitleLabel.layer.mask === cell.maskTitleMaskLayer)
        XCTAssertEqual(cell.maskTitleMaskLayer.frame, topFrame)
        XCTAssertFalse(cell.maskTitleLabel.isHidden)
    }

    func testActiveAnimationKeepsInterpolatedColorAndAnimator() {
        let model = model()
        model.isSelectedAnimable = true
        model.selectedAnimationDuration = 100
        let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
        cell.reloadData(itemModel: model, selectedType: .click)
        let animator = cell.animator
        animator?.progressClosure?(0.35)
        let expected = model.titleCurrentColor
        cell.isHighlighted = true
        cell.isHighlighted = false
        cell.isSelected = true
        XCTAssertEqual(cell.titleLabel.textColor, expected)
        XCTAssertTrue(cell.animator === animator)
        XCTAssertTrue(model.isTransitionAnimating)
        animator?.stop()
        XCTAssertEqual(cell.titleLabel.textColor.resolvedColor(with: cell.traitCollection).cgColor, UIColor.red.cgColor)
        XCTAssertFalse(model.isTransitionAnimating)
    }

    func testReuseStopsOldAnimationAndRendersNewModel() {
        let old = model()
        old.isSelectedAnimable = true
        let cell = JXSegmentedTitleCell(frame: CGRect(x: 0, y: 0, width: 180, height: 44))
        cell.reloadData(itemModel: old, selectedType: .click)
        cell.prepareForReuse()
        XCTAssertNil(cell.animator)
        let new = model(selected: false)
        new.titleCurrentColor = .blue
        cell.reloadData(itemModel: new, selectedType: .unknown)
        cell.isSelected = false
        cell.isHighlighted = true
        cell.isHighlighted = false
        XCTAssertEqual(cell.titleLabel.textColor, .blue)
        XCTAssertTrue(cell.itemModel === new)
    }

    func testGradientLayerSurvivesHighlightAndSelection() {
        let model = JXSegmentedTitleGradientItemModel()
        model.title = "Gradient"
        model.titleCurrentColor = .black
        model.titleCurrentGradientColors = [UIColor.blue.cgColor, UIColor.green.cgColor]
        let cell = JXSegmentedTitleGradientCell(frame: CGRect(x: 0, y: 0, width: 160, height: 44))
        cell.reloadData(itemModel: model, selectedType: .unknown)
        cell.layoutIfNeeded()
        let colors = cell.gradientLayer.colors as? [CGColor]
        cell.isHighlighted = true
        cell.isSelected = true
        cell.isHighlighted = false
        XCTAssertEqual(cell.gradientLayer.colors as? [CGColor], colors)
        XCTAssertTrue(cell.gradientLayer.mask === cell.titleLabel.layer)
        XCTAssertEqual(cell.titleLabel.textColor, model.titleCurrentColor)
    }

    func testMaskReuseRestoresPlainLabelAndCurrentColor() {
        let masked = model()
        masked.isTitleMaskEnabled = true
        masked.indicatorConvertToItemFrame = CGRect(x: 10, y: 0, width: 80, height: 44)
        let cell = cell(masked)
        cell.prepareForReuse()
        let plain = model(selected: false)
        plain.titleCurrentColor = .blue
        cell.reloadData(itemModel: plain, selectedType: .unknown)
        cell.isSelected = false
        cell.isHighlighted = false
        XCTAssertTrue(cell.maskTitleLabel.isHidden)
        XCTAssertNil(cell.titleLabel.layer.mask)
        XCTAssertNil(cell.maskTitleLabel.layer.mask)
        XCTAssertEqual(cell.titleLabel.textColor, .blue)
    }

    func testAutomaticWidthContainsBothNormalAndSelectedFonts() {
        for title in ["发现与活动", "المجتمعات والأنشطة", "Discover"] {
            for (normal, selected) in [(UIFont.systemFont(ofSize: 13), UIFont.boldSystemFont(ofSize: 28)), (UIFont.systemFont(ofSize: 30), UIFont.boldSystemFont(ofSize: 12))] {
                let source = JXSegmentedTitleDataSource()
                source.titleNormalFont = normal
                source.titleSelectedFont = selected
                XCTAssertEqual(source.widthForTitle(title, 0), max(width(title, normal), width(title, selected)), accuracy: 0.01)
            }
        }
    }

    func testDynamicConfigurationUsesFontsAtEachIndex() {
        let source = JXSegmentedTitleDataSource()
        let config = Fonts()
        source.configuration = config
        for index in 0..<3 {
            let title = ["发现", "العربية", "Dynamic"][index]
            let normal = config.titleNormalFont(at: index)
            let selected = config.titleSelectedFont(at: index) ?? normal
            XCTAssertEqual(source.widthForTitle(title, index), max(width(title, normal), width(title, selected)), accuracy: 0.01)
        }
    }

    func testWidthClosureFixedWidthAndExistingZoomScalingRemainAuthoritative() {
        let source = JXSegmentedTitleDataSource()
        source.titles = ["发现", "العربية"]
        source.titleSelectedFont = .boldSystemFont(ofSize: 40)
        source.widthForTitleClosure = { $0 == "发现" ? 77 : 88 }
        source.itemWidthIncrement = 6
        source.reloadData(selectedIndex: 0)
        let view = JXSegmentedView()
        XCTAssertEqual(source.widthForTitle("发现", 0), 77)
        XCTAssertEqual(source.preferredSegmentedView(view, widthForItemAt: 0), 83)
        source.itemWidth = 100
        XCTAssertEqual(source.preferredSegmentedView(view, widthForItemAt: 1), 106)
        source.isTitleZoomEnabled = true
        source.titleSelectedZoomScale = 1.4
        source.reloadData(selectedIndex: 0)
        XCTAssertEqual(source.segmentedView(view, widthForItemContentAt: 0), 77 * 1.4, accuracy: 0.01)
        XCTAssertEqual(source.segmentedView(view, widthForItemContentAt: 1), 88, accuracy: 0.01)
    }

    func testPrivacyManifestIsInSwiftPackageBundle() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any]
        XCTAssertEqual(plist?["NSPrivacyTracking"] as? Bool, false)
    }

    private func width(_ title: String, _ font: UIFont) -> CGFloat {
        ceil(NSString(string: title).boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: font], context: nil).width)
    }
}

private final class Fonts: NSObject, JXSegmentedTitleDynamicConfiguration {
    func titleNumberOfLines(at index: Int) -> Int { 1 }
    func titleNormalColor(at index: Int) -> UIColor { .black }
    func titleSelectedColor(at index: Int) -> UIColor { .red }
    func titleNormalFont(at index: Int) -> UIFont { .systemFont(ofSize: CGFloat(12 + index * 3)) }
    func titleSelectedFont(at index: Int) -> UIFont? { index == 2 ? nil : .boldSystemFont(ofSize: CGFloat(30 + index * 2)) }
}
