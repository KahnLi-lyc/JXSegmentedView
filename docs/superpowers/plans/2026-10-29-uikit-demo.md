# JXSegmentedView 独立 UIKit Demo 实施记录

目标：通过公开接口和本地 Package 提供可直接打开的 UIKit 示例，以及全部现有公开能力的功能覆盖表。保持 Swift 6 / iOS 16，不改变 Product、库 API、上游基线或消费者 revision。

工程：Demo/project.yml 使用 XcodeGen 2.46.0，生成工程和共享 Scheme 一并提交。应用支持 iPhone / iPad / 横竖屏。新版 XCTest SDK 测试目标 iOS 17，库与应用仍为 iOS 16。

交付：功能场景、可操作控件、实际状态面板、公开接口集成测试及 UI 测试；使用文档和覆盖表区分自动化与人工检查。详情在 Demo/README.md、Demo/COVERAGE.md 与覆盖索引中。

验收：使用任务独占 Simulator 串行测试，构建 jobs=2，保留日志和 xcresult。运行现有库回归、Swift 5/6 消费者、Demo 工程一致性、实际 App 隐私资源和并发诊断检查。Swift 6.0 / iOS 16、真机、VoiceOver 和视觉连续性只按实际执行记录，不推断通过。

维护：CI 下载并校验固定 XcodeGen，45 分钟任务上限，自建并清理设备，失败保存结果。独立 feature/uikit-demo 分支，示例与回归、CI 与文档分别提交；全部验收后普通合并 master、复验、尝试一次普通 push，不改写历史、不新建 Tag，spm 保持冻结。
