# 主分支维护与上游升级

本库是独立维护、可用于不同项目的通用 UIKit 库。

## 分支与远端

| 名称 | 职责 |
| --- | --- |
| `origin/master` | 自有 fork 的正式维护和默认分支 |
| `feature/*`、`fix/*` | 从当前 master 创建，完成验证后合并的任务分支 |
| `origin/spm` | 冻结在 `f92aa529378f7d5ef3f39e5ac226864f9d2c6094` 的过渡分支，不再独立迭代 |
| `upstream/master` | 原作者仓库的远端跟踪分支，用于审查候选更新 |

`origin` 为 `https://github.com/KahnLi-lyc/JXSegmentedView.git`，
`upstream` 为 `https://github.com/pujiaxin33/JXSegmentedView.git`。
SourceTree 日常检出本地 `master`，从它创建任务分支；验证后切回 master 并合并任务分支。
将自有 master 推送到 origin，不将任务修改直接推往 upstream。

## 日常修复

```sh
git switch master
git fetch origin master
git merge --ff-only origin/master
git switch -c fix/title-layout
# 完成当前任务后，在专用且已启动的 iOS Simulator 上验证。
scripts/test-ios.sh <专用Simulator-UUID>
git diff --check
git add <当前任务文件>
git commit -m "fix: 修复当前任务问题"
git switch master
git merge --no-ff fix/title-layout -m "merge: 合入已验证修复"
# 对合并后的 master 再执行相同回归。
scripts/test-ios.sh <专用Simulator-UUID>
git push origin master
```

若 master 已前进，执行普通合并并重新验证；冲突时逐项审查，不能强推覆盖远端。
任务结束并确认提交已由 master 持有、无本地文件遗漏后，再删除自己的临时分支。
消费者固定完整 commit revision；master 前进不会自动升级已锁定的项目。
当前没有新建版本 Tag，需要发布版本时另行制定并授权版本规则。

## 首次迁移的特殊处理

2026-10-29 从已验收 spm 创建临时分支，对旧 master `49d8b0755f4877febd3251471e3347880f785c96` 做一次
`ours` 策略的历史合并。该合并的首父为已验收 spm，第二父为旧 master；
源码树保持 spm，仅维护文档更新。随后自有 master 快进到此合并结果。

这样保留双方完整历史并建立唯一维护入口，不需要 reset、rebase 或 force-push。
这是一次性的分支收敛策略，日常功能合并不使用 ours。未采纳的上游内容见
[上游审查记录](UPSTREAM_REVIEW.md)，不能仅凭祖先关系判断源码已完成升级。

## 上游候选升级

```sh
git fetch --no-tags upstream master
git switch master
git switch -c upgrade/upstream-review
git diff fbbf965d7396bd99ac1ce88a80b6c950b85313f6 upstream/master -- Sources Package.swift
```

先按上游审查记录确认真正采纳的基线，再逐项移植需要的修复；有部分内容不适合当前
Swift 分发结构时保留现有结构，不恢复已剔除的分发内容。直接 cherry-pick 较新提交前，
必须检查它依赖的旧提交；不把 Git 的 clean merge 当成行为兼容证明。
更新审查记录、补丁说明和行为测试，完成 package 回归、隐私资源与实际消费者验证后，
按日常修复流程合入 master。只有完整采纳并验证目标版本，才更新整体上游基线。
Swift 6 语言模式适配应独立立项，不与本次分支迁移混合。
