# UIKit Demo 验证记录

日期：2026-10-29。此记录区分编译、自动化运行与人工验收。

## 本机工具链

- Xcode 27.1 (27A9275)，Apple Swift 6.4，macOS 27.0.1。
- App／Package 使用 Swift 6 语言模式、iOS 16 最低系统版本；测试宿主因现代 SDK XCTest 动态库下限设为 iOS 17。
- XcodeGen 2.46.0，提交生成工程，共享 Scheme `JXSegmentedViewDemo`。

## 已取得证据

- 本地 Package、Demo App、测试目标 generic Simulator build-for-testing 编译；编译与运行分开记录。
- XcodeGen 重新生成无工程差异；功能覆盖索引和测试引用检查。
- 实际 App 包的 Package PrivacyInfo.xcprivacy 存在且可解析。
- Swift 5／Swift 6 宿主公开接口编译；依赖库保持 Swift 6 语言模式。
- 没有新增 Swift 源码或并发诊断。Xcode AppIntents 元数据及链接器诊断独立保存在原始日志，不计为源码检查通过依据。

## 运行验收进度

本轮新增 `5 公开接口 + 24 UI` 测试定义。完整 Demo 运行结果待托管 CI／专用设备实际取得后更新，不能由编译推断通过。

本机 CoreSimulator 在高负载期间出现 UIKit 显示配置服务等待、应用启动和 spawn 长时间阻塞。保留日志及采样；仅操作本任务设备，不重启共享 CoreSimulatorService。首轮分页测试暴露的测试夹具假设已修正，首轮失败结果仍保留。分页原库 7 项基线在 iOS 27.0 重试通过；分段原库基线在本轮尚未重新运行。

原始证据位于工作区外 `SwiftLibraries/.validation/2026-10-29-uikit-demos/`，结果包不进入仓库。后续验收结果以实际 xcresult 和 CI 链接补充。

## 未验证边界

Swift 6.0 最低工具链、iOS 16 运行、真机、真实 VoiceOver、动画连续性和触摸按下／取消时的视觉验收尚未执行。iPad 重点运行待取得结果。Demo 的环境菜单和 UI 自动化不等同于这些人工验收。
