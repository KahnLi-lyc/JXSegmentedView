# Swift 6 并发适配实施计划

目标：Swift tools 6.0、Swift 6 语言模式、iOS 16，保持通用 UIKit 功能与模块名。
本清单保存用户批准的实施范围，实际结果记入 VALIDATION.md。

- [ ] 独立 worktree 与 feature/swift6-concurrency；原测试与 Swift 5 complete / Swift 6 诊断基线。
- [ ] UI 协议和可变状态主 Actor 隔离；同步回调与 Objective-C 入口维持顺序。
- [ ] 受控 KVO token 管理；替换观察、重载、清理后旧事件失效。
- [ ] 分段库动画器弱目标、停止与释放；旧动画及延迟选中不得污染新状态。
- [ ] 原回归及新增生命周期、滚动、动画测试；Swift 5/6 公开接口宿主夹具。
- [ ] GitHub Actions、并发诊断门禁、隐私资源产物检查、日志和 xcresult。
- [ ] 临时 ClubCircleUI 集成与 Demo 验证，不更新正式消费者锁文件。
- [ ] README / 维护 / Swift 6 迁移说明与实际验收边界。
- [ ] 独立源码与 CI 文档提交，合入 master 复验，各一次普通 push，安全清理。

限制：不升级上游，不引入 OC 分发，不使用默认 MainActor 掩盖隔离，不批量 unsafe Sendable，不新建 Tag/PR，不改写历史。Swift 6.0 / iOS 16 只有实际执行后才称已验证。
