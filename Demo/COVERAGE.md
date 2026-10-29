# 功能覆盖与人工验收

机器可读索引为 `Resources/route-coverage.json`。所有入口和固定 preset 都有 UI 操作与选择／回调断言，不穷举全部配置组合。

| 入口 | 配置 | 公开能力 | 自动化 | 人工状态 |
| --- | --- | --- | --- | --- |
| titles | Classic / Color transition / Click animation | JXSegmentedTitleDataSource、titleNormalColor、titleSelectedColor、isTitleColorGradientEnabled、isSelectedAnimable | CatalogUITests/testTitlesRoute | 视觉／VoiceOver 待人工 |
| attributed | Rich text / Selected text / Width closure | JXSegmentedTitleAttributeDataSource、attributedTitles、selectedAttributedTitles、widthForTitleClosure | CatalogUITests/testAttributedRoute | 视觉／VoiceOver 待人工 |
| gradient | Horizontal / Vertical | JXSegmentedTitleGradientDataSource、titleNormalGradientColors、titleSelectedGradientColors、titleGradientStartPoint、titleGradientEndPoint | CatalogUITests/testGradientRoute | 视觉／VoiceOver 待人工 |
| images | Top / Left / Bottom / Right / Image only / Title only / Background | JXSegmentedTitleImageDataSource、topImage、leftImage、bottomImage、rightImage、onlyImage、onlyTitle、backgroundImage、loadImageClosure、normalImageInfos、selectedImageInfos、isImageZoomEnabled | CatalogUITests/testImagesRoute | 视觉／VoiceOver 待人工 |
| title-or-image | Replace all / Mixed replacements | JXSegmentedTitleOrImageDataSource、selectedImageInfos、loadImageClosure | CatalogUITests/testTitleOrImageRoute | 视觉／VoiceOver 待人工 |
| badges | Dots / Numbers / Formatted numbers | JXSegmentedDotDataSource、dotStates、dotOffset、dotSize、JXSegmentedNumberDataSource、numbers、numberStringFormatterClosure | CatalogUITests/testBadgesRoute | 视觉／VoiceOver 待人工 |
| indicators | Line / Lengthen / Lengthen offset / Triangle / Background / Gradient background / Gradient line / Rainbow / Double line / Dot line / Image / None / Multiple / Top / fixed / Content width / inset / No scroll transition | JXSegmentedIndicatorLineView、normal、lengthen、lengthenOffset、JXSegmentedIndicatorTriangleView、JXSegmentedIndicatorBackgroundView、JXSegmentedIndicatorGradientView、JXSegmentedIndicatorGradientLineView、JXSegmentedIndicatorRainbowLineView、JXSegmentedIndicatorDoubleLineView、JXSegmentedIndicatorDotLineView、JXSegmentedIndicatorImageView、empty indicators、multiple indicators、indicatorPosition、indicatorWidth、indicatorHeight、indicatorWidthIncrement、indicatorCornerRadius、verticalOffset、isIndicatorWidthSameAsItemContent、isScrollEnabled | CatalogUITests/testIndicatorsRoute | 视觉／VoiceOver 待人工 |
| layout | Natural / Fixed / Width closure / Increment / Average spacing / Fixed spacing / Edge insets / Item content width | JXSegmentedViewAutomaticDimension、itemWidth、widthForTitleClosure、itemWidthIncrement、isItemSpacingAverageEnabled、itemSpacing、contentEdgeInsetLeft、contentEdgeInsetRight、content width versus cell width | CatalogUITests/testLayoutRoute | 视觉／VoiceOver 待人工 |
| typography | Per-item fonts / Multiline / Long titles / Mask / Stroke / Title zoom / Width zoom / No transition | JXSegmentedTitleDynamicConfiguration、titleNormalFont、titleSelectedFont、titleNumberOfLines、long title scrolling、isTitleMaskEnabled、isTitleStrokeWidthEnabled、isTitleZoomEnabled、isItemWidthZoomEnabled、isItemTransitionEnabled | CatalogUITests/testTypographyRoute | 视觉／VoiceOver 待人工 |
| containers | Scroll container / Collection container / Direct scroll view / Start on third / Lazy threshold | JXSegmentedListContainerView.scrollView、JXSegmentedListContainerView.collectionView、contentScrollView、defaultSelectedIndex、initListPercent、validListDict、listWillAppear、listDidAppear、listWillDisappear、listDidDisappear | CatalogUITests/testContainersRoute | 视觉／VoiceOver 待人工 |
| nested | Nested horizontal / Nested collection | nested segmented view、nested list container、vertical list scrolling、independent inner selection | CatalogUITests/testNestedRoute | 视觉／VoiceOver 待人工 |
| navigation | Title view / Compact title view | UINavigationItem.titleView、navigation push and back | CatalogUITests/testNavigationRoute | 视觉／VoiceOver 待人工 |
| custom | Custom capsule / Custom indicator | JXSegmentedTitleItemModel subclass、JXSegmentedBaseCell subclass、JXSegmentedTitleDataSource subclass、registerCellClass、preferredRefreshItemModel、JXSegmentedIndicatorBaseView subclass、refreshIndicatorState、contentScrollViewDidScroll、selectItem | CatalogUITests/testCustomRoute | 视觉／VoiceOver 待人工 |
| dynamic | Mutable titles / Animated selection | empty restore、insert、delete、reorder、reloadItem、reloadData、replace contentScrollView、old scroll observation isolation、rapid selectItemAt、canClickItemAt、didSelectedItemAt、didClickSelectedItemAt、didScrollSelectedItemAt、scrollingFrom | CatalogUITests/testDynamicRoute | 视觉／VoiceOver 待人工 |

额外重点用例覆盖真实标题点击／横滑、两种容器及惰性创建、空恢复与增删重排、独立内容滚动视图替换、快速选择、嵌套内外选择、创建门禁、真实动画配置与 iPad 旋转。底层颜色、字宽、动画释放及过期事件继续由原 Package 回归承担。

人工检查清单：深浅色、RTL 中英文／阿拉伯语长标题、横竖屏和 iPad 视觉布局；VoiceOver 朗读、选择状态、焦点顺序；系统 Reduce Motion；触摸按下／取消、滑动回弹、快速切换过程的颜色与裁切。未执行检查保留待执行，不将 UI 冒烟等同于这些检查通过。

隐私资源由 `scripts/check-demo-resources.py` 检查实际 App 产物。`docs/DEMO_VALIDATION.md` 记录工具链、运行设备、测试数量及未验证环境。
