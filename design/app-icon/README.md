# App 图标和 Logo

## 现在用的

- App 图标：`第1批/L3-gauge-buddy.png`（会笑的仪表盘，橙到珊瑚红渐变底）。缩成 1024、转 sRGB 后存为 `正式资源/AppIcon-1024.png`，再生成全部尺寸放进 `Monitto/Assets.xcassets/AppIcon.appiconset`。
- DMG 安装窗口背景按图标主色 `FD6A2C` 重新生成。

## 抽卡记录

每批的图和提示词（`prompts/`）都在对应目录里。

- 第1批（20 张）：L3 中选。果冻、软陶、粗描边、轻 3D、渐变矢量、深色符号六种画法，主角围绕温度计、仪表、听诊器、风扇、心跳线。S3 第一版护士帽上有红十字，去掉后重画为 `S3-cat-stetho-v2.png`。

对比图不进仓库，需要时重新生成：

```sh
swift ~/.agents/skills/icon-logo/scripts/contact-sheet.swift design/app-icon/第1批
```
