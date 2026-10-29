# Swift 6 迁移指南

本次维护将 SPM 分发的最低工具链提升至 Swift 6.0，正式使用 Swift 6 语言模式，最低系统为 iOS 16。模块和 product 名不变；Swift 5 模式宿主仍可用现代工具链接入，但 Swift 5.3 等旧工具链不能解析新 manifest。原来的完整 revision 和冻结 spm 分支继续可用。

## 主线程约定

所有 UI 数据源、代理、列表和展示状态均由主 Actor 管理。UIKit 子类继承隔离；NSObject 适配器建议显式声明 `@MainActor`。后台工作只产生数据，在 `await MainActor.run { ... }` 内更新组件。不要把 UIKit 对象声明为 unchecked Sendable。

此前为 Swift 5 第三方覆写添加的 `nonisolated` 应移除；原本同步的 UI 访问不再需要 `MainActor.assumeIsolated` 包装。隔离标注是有意的源码兼容变化，升级消费者前先编译其自定义子类和代理。公开名称、参数标签、默认值和同步交互保持原样，不承诺 ABI 兼容。

## KVO 与生命周期

内部通过受控 NSKeyValueObservation token 观察 UIKit 滚动属性；重载和替换先释放旧 token。保留 open observeValue 钩子及其 keyPath / object / change kind / event newValue。非隔离 Foundation 入口通过主线程前置检查同步进入 MainActor，不使用异步派发改变滚动顺序。UIKit 属性仍必须在主线程修改；这不提供跨线程修改 UIScrollView 的能力。

不在 deinit 调用 UIKit 或子页方法。宿主按既有约定管理控制器 containment 和生命周期；列表注册回调不得形成宿主自身的强引用环。

## 验证与持续集成

```sh
scripts/test-ios.sh <dedicated-simulator-uuid> /tmp/Library-DD -- -resultBundlePath /tmp/Library-tests.xcresult SWIFT_STRICT_CONCURRENCY=complete
scripts/check-consumer.sh /tmp/fresh-consumer-output
scripts/check-concurrency-diagnostics.sh /tmp/build.log
```

`Fixtures/Consumer` 使用公开 import，独立 Swift 5、Swift 6 target，各自明确语言模式，依赖库保持 Swift 6。不要全局覆盖 SWIFT_VERSION 来伪造宿主兼容测试。CI 在托管 macOS 默认 Xcode 上创建专用设备，串行执行回归与宿主构建，保存完整日志和 xcresult。并发警告门禁不屏蔽 SDK／弃用诊断。

工具链下限声明不等于最低工具链已运行验证；实际设备、系统、编译器和托管 CI 结果以 VALIDATION.md 为准。

## 分段栏 API

数据源、动态标题配置、列表／代理、RTL、指示器协议及可变展示模型归 MainActor。标题宽度闭包、LoadImageClosure 和动画回调携带 MainActor 约定。图片请求继续由宿主管理，完成后回到主 Actor 设置 UIImageView。动画闭包别名显式为 MainActor Sendable，不为非隔离的可变模型提供传输豁免。纯数值插值保持非隔离。

```swift
@MainActor
final class Titles: JXSegmentedTitleDataSource {
    override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        JXSegmentedTitleItemModel()
    }
}
```

JXSegmentedAnimator 的首次 stop 或自然完成仍先发送最终 progress(1) 再调用 completion；重复 stop 不再重复回发，结束后释放回调。弱 display-link target 避免动画器自持有，所有者消失后下一次主 run-loop 帧清理孤立 link，不从析构触发用户回调。

Cell 重载先结束旧动画，旧 completion 通过动画器身份验证避免清理新状态。模型通过弱动画所有者识别已释放的动画，手动写 isTransitionAnimating 仍保留原语义。宽度动画弱引用分段视图；延迟选中使用弱引用和更新代次校验。

UIKit 隐式 Actor 继承在本机 Swift 6.4 的跨文件回调类型符号上出现不一致；基类 Cell 显式 MainActor 保持正确语义并避免该问题。没有启用 WMO、unsafe 标注或关闭检查来绕过它。

## ClubCircleUI 后续升级注意

临时集成副本必须移除 SegmentedTitleSource 的 5 个 `override nonisolated` 标注，改为主 Actor 覆写；同时移除已多余的 MainActor.assumeIsolated 包装、preconcurrency import 和 JX 协议上的 preconcurrency 标注。分页适配器的 listViewDidScrollCallback 参数显式添加 MainActor。本次只验证副本，不提交正式工程、manifest 或锁文件；消费者 revision 升级为独立任务。
