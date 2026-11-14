# AGENTS.md

## 项目概览

- Monitto 是使用 SwiftUI 与 AppKit 开发的 macOS 菜单栏应用，入口位于 `Monitto/MonittoApp.swift`。
- 工程文件为 `Monitto.xcodeproj`，应用 Target 与主 Scheme 均为 `Monitto`。
- 当前 Swift 版本为 5.0，最低系统版本由工程中的 `MACOSX_DEPLOYMENT_TARGET` 定义。
- Swift Package 依赖包括 Sparkle。
- `Monitto/Models` 存放数据模型与偏好键，`Monitto/Services` 存放采样和系统服务，`Monitto/Views` 存放页面，`Monitto/Views/Components` 存放共用组件。
- 发布流程以 `docs/RELEASING.md` 为准，不得手工修改生成的 appcast。

## 修改原则

- 修改前先搜索并完整阅读最相近的现有实现，复用现有组件、颜色、动画、布局和状态管理方式。
- 只修改当前需求直接涉及的代码；禁止顺手重构、格式化无关文件或增加未要求的机制。
- 涉及首页卡片时，优先复用 `DashboardGrid.swift`、`SummaryView.swift` 和 `Motion.swift` 中的布局与动画基线。
- 保留现有 `PreferenceKey`、`UserDefaults` 和 `@AppStorage` 的持久化兼容性；需要改变已保存数据结构时必须明确处理迁移。
- 不得把密钥、令牌、证书、签名材料或本机凭据写入仓库。
- 未经用户在当前任务中明确允许，不得 commit、push、创建分支或使用 Git worktree。
- 未经用户明确允许，不得使用浏览器控制或 Computer Use 做界面操作和视觉验收。

## 构建与验证

- 当前工程没有测试 Target。代码修改后至少执行差异检查和 Debug 构建：

```bash
git diff --check
xcodebuild -project Monitto.xcodeproj -scheme Monitto -configuration Debug -derivedDataPath "$PWD/DerivedData" build
```

- 若后续加入测试 Target，应同时运行与改动相关的测试。
- 构建失败时必须保留当前运行实例，并先报告或修复构建错误，不得启动失败或过期的产物。

## 运行最新版

- 每次完成代码修改并验证构建成功后，必须关闭所有正在运行的旧 Monitto 实例，再启动刚构建的 `$PWD/DerivedData/Build/Products/Debug/Monitto.app`。
- 终止进程前必须先通过完整可执行文件路径确认 PID，只关闭 Monitto 实例，不得使用会误伤其他应用的宽泛进程匹配。
- 启动后再次检查进程列表，确保只运行一个来自项目内 Debug 构建目录的 Monitto 实例，便于用户直接验收最新效果。
- 仅文档变更不要求重新构建或重启应用。

## 发布版本

- 完整发布说明以 `docs/RELEASING.md` 为准；任何发布方式都不得手工修改生成的 `appcast.xml`，不得移动已经发布的版本标签。
- 发版必须按全局技能 `mac-release` 使用共用脚本 `~/.agents/skills/mac-release/scripts/mac-release <MAJOR.MINOR.PATCH>`（Monitto 的配置在 `scripts/release-config.sh`），不得手工重复脚本中的构建、签名、公证、打包、签名 appcast、打标签和创建 GitHub Release 步骤。
- 运行发布脚本前，必须确认当前位于 `master`、工作区干净、`HEAD` 已推送并与 `origin/master` 完全一致，`gh auth status` 有效，登录钥匙串内有 Developer ID Application 证书、名为 `notary` 的公证凭据，以及账户名为 `com.seaony.Moni` 的 Sparkle 私钥（和 CodeEdge、Diskit 共用）。
- 发布脚本会从最新 appcast 推导递增的 bundle build number，构建 `arm64` 与 `x86_64` 通用应用，用 Developer ID 签名并开启 Hardened Runtime，公证并装订 DMG，生成 ZIP 和带 EdDSA 签名的 appcast，完成验证后推送注释标签并创建 GitHub Release；产物保存在 `build/releases/vMAJOR.MINOR.PATCH/`。
- 发布脚本不会替代源码的 commit 与 `master` push。用户要求“发版本”时，应先完成并推送当前源码提交，再运行发布脚本；脚本中途失败时，修复已确认的失败原因后以同一条命令重跑，它会接着上次的进度。
