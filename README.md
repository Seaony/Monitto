<div align="center">
  <img src="Monitto/Assets.xcassets/AppIcon.appiconset/AppIcon-128@2x.png" width="128" height="128" alt="Monitto 图标">
  <h1>Monitto</h1>
  <p>点一下菜单栏，看清这台 Mac 现在的状态。</p>
  <p>
    <a href="https://github.com/Seaony/Monitto/actions/workflows/build.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/Seaony/Monitto/build.yml?branch=master&amp;style=flat-square&amp;label=build"></a>
    <a href="https://github.com/Seaony/Monitto/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/Seaony/Monitto?display_name=tag&amp;style=flat-square"></a>
    <img alt="macOS 26.5+" src="https://img.shields.io/badge/macOS-26.5%2B-111111?style=flat-square&amp;logo=apple">
    <img alt="Swift 5" src="https://img.shields.io/badge/Swift-5-F05138?style=flat-square&amp;logo=swift&amp;logoColor=white">
  </p>
</div>

Monitto 是一个 macOS 菜单栏 App。CPU、内存、GPU、网络、磁盘、进程、电池和温度都收在一个弹出面板里，最关心的几项也可以直接挂在菜单栏上。

## 能做什么

- **首页概览**：主机信息、CPU、内存、GPU、网络、存储、进程，以及电池、温度、风扇转速和功耗。鼠标停在图表上能看到具体数值和说明。
- **自己排首页**：卡片可以拖动排序、调整大小，不看的模块可以关掉，布局会记住。
- **菜单栏指标**：从 CPU、内存、网络、磁盘、电池、温度里任选几项，显示成数值、小图表或两者都显示。
- **超限提醒**：CPU、内存、磁盘用量或 CPU 温度超过你设的阈值时，发系统通知或播放提示音。
- **外观和语言**：浅色、深色或跟随系统；界面有英文和简体中文；整个面板可以缩放。
- **不费电**：所有数据共用一次采样，开销大的采样在面板关闭时降频或暂停。

## 安装

从 [Releases](https://github.com/Seaony/Monitto/releases/latest) 下载 DMG，打开后把 Monitto 拖进「应用程序」。安装包用 Developer ID 签名并经过 Apple 公证，可以直接打开；有新版本时 App 里会提示更新。

需要 macOS 26.5 或更新版本，Apple 芯片和 Intel 芯片的 Mac 都能用。

## 用法

1. 点菜单栏里的 Monitto 打开面板。
2. 鼠标停在图表或数值上，查看具体数据和说明。
3. 在面板里按 `⌘,` 打开设置，按 `Esc` 回到首页，按 `⌘R` 立即刷新。

## 数据与隐私

系统指标都在本机读取，不会上传。Monitto 只在检查更新时联网，检查失败也不影响监控。

每项数据从哪来、怎么算、多久采一次，见 [数据源审计清单](docs/DATA_SOURCE_AUDIT.md)。

## 从源码构建

需要 Xcode 26.6：

```bash
git clone https://github.com/Seaony/Monitto.git
cd Monitto
xcodebuild \
  -project Monitto.xcodeproj \
  -scheme Monitto \
  -configuration Debug \
  -derivedDataPath "$PWD/DerivedData" \
  build
open DerivedData/Build/Products/Debug/Monitto.app
```

目录：

```text
Monitto/   App 代码：页面、数据模型和采样服务
Shared/    本地化
scripts/   发版配置和 DMG 安装窗口
docs/      数据源审计和发版说明
design/    图标源文件和历次候选
```

发版流程见 [发版说明](docs/RELEASING.md)。
