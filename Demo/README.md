# JXSegmentedView UIKit Demo

直接打开 `JXSegmentedViewDemo.xcodeproj`，运行同名共享 Scheme。该工程只引用上一级本地 Swift Package，不依赖 JXPagingView、CocoaPods、远程图片或业务项目。上游旧 `Example/` 保留为参考；本目录是当前维护入口。

应用／库下限仍为 Swift 6 语言模式、iOS 16。新版 Xcode 的 XCTest 动态库下限为 iOS 17，测试目标单独设为 iOS 17，不改变 Demo 应用或库的兼容要求。

工程由 **XcodeGen 2.46.0** 的 `project.yml` 生成并随仓库提交。配置或文件列表变化后，在仓库根运行 `xcodegen generate --spec Demo/project.yml`，一起提交工程和 Scheme；CI 检查生成无差异。

## 使用方法

目录共有 14 个功能入口。每个场景通过 `Next preset` 切换固定配置，点击实际分段标题、`Previous`／`Next tab` 或横向滑动页面，观察真实选中项和回调。`Dynamic data & lifecycle` 另有空／恢复、插入、删除、重排、单项／整体刷新、替换内容滚动视图和快速切换操作。

右上角环境菜单支持系统／深色／浅色、RTL 和减少动画；真实系统 Reduce Motion 也参与动画配置。颜色、图片和内容全部离线可用。不同宽度及方向由当前 bounds 布局，支持 iPhone 和 iPad。

接入示例按职责拆分：`Catalog` 定义稳定场景；`LabFactory` 配置公开数据源与全部内置指示器；`LabViewController` 负责分段与内容容器联动；`PageList` 展示列表生命周期与嵌套；`CustomExtensions` 展示公开扩展点。示例代码没有 @testable 导入或底层防闪补丁。

```swift
// 宿主需强持有 source；segmented.dataSource 是弱引用。
let source = JXSegmentedTitleDataSource()
source.titles = ["Following", "Discover", "Saved"]
source.titleNormalColor = .secondaryLabel
source.titleSelectedColor = .label
let segmented = JXSegmentedView()
segmented.dataSource = source
let line = JXSegmentedIndicatorLineView()
line.indicatorColor = .systemIndigo
segmented.indicators = [line]
// 将 segmented 添加到布局后刷新；分页联动的完整宿主见 LabViewController。
segmented.reloadData()
```

动态修改 source 后需要调用对应公开刷新 API。普通列表容器、collection 容器和直接绑定 UIScrollView 的接法分别有独立 preset；使用非首项时保持容器和分段 defaultSelectedIndex 一致。图片闭包只做主 Actor 上的离线赋值；真实网络加载和取消应由宿主管理。

## 自动化

在仓库根使用自己创建、已完成 bootstatus 的设备：

```sh
scripts/test-demo.sh <dedicated-booted-simulator-uuid> /tmp/jxsegmented-demo-fresh
```

脚本执行公开接口集成测试和 UI 测试，保存完整日志、DerivedData 和 xcresult，验证 App 产物内的 Package 隐私资源。iPad 重点用例可追加 `-only-testing:JXSegmentedViewDemoUITests/CatalogUITests/testIPadResizeAndCollectionContainer`。

[覆盖表](COVERAGE.md) 映射每个功能到入口和测试。运行结果在 `docs/DEMO_VALIDATION.md`。自动化选择状态与几何检查不能替代真实 VoiceOver、字体裁切和过渡动画的人工视觉验收。
