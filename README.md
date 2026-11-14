<div align="center">

<a href="https://github.com/Seaony/Monitto/releases/latest"><img src="docs/assets/icon-512.png" width="112" alt="Monitto"></a>

# Monitto

### Your Mac, at a glance.

**CPU, memory, GPU, network, storage, processes, battery and temperature, in one menu bar panel.**<br>
Keep the few numbers you care about in the menu bar,<br>
and get a notification when one of them runs too high.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white) ![Swift 5](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white) ![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF?logo=swift&logoColor=white)

**[Download](https://github.com/Seaony/Monitto/releases/latest)** &nbsp;·&nbsp; **[Releasing](docs/RELEASING.md)** &nbsp;·&nbsp; **English** · [简体中文](README.zh-CN.md)

</div>

<br>

## Is Monitto for you?

When your Mac gets slow, hot or loud, the answer is spread across several places: Activity Monitor for CPU and memory, System Settings for the battery, and temperature and fan speed aren't shown anywhere.

Monitto puts all of it in one panel under its menu bar icon:

- **See everything at once**: host, CPU, memory, GPU, network, storage and processes, plus battery, temperature, fan speed and power draw. Each is a card with a live chart; hover a chart for exact values.
- **Arrange it your way**: drag cards to reorder them, resize them, and hide the ones you don't need.
- **Keep key numbers in the menu bar**: pick any of CPU, memory, network, disk, battery and temperature, shown as numbers, small charts or both.
- **Hear about it when something runs hot**: set limits for CPU load, memory, disk space and CPU temperature, and get a notification, with an optional sound.

It's for you if you want to know what your Mac is doing without opening several apps. If Activity Monitor already tells you enough, you don't need it.

## Quick start

**1 · Install.** Download the DMG from the **[latest release](https://github.com/Seaony/Monitto/releases/latest)**, open it and drag `Monitto.app` into Applications.

<sub>Builds are universal (Apple silicon and Intel) and need macOS 15 or later. Monitto updates itself from GitHub Releases through Sparkle.</sub>

**2 · Open the panel.** Click the Monitto icon in the menu bar. Hover a chart or a number to see what it means; press **⌘R** to refresh.

**3 · Set it up.** Click **Settings ⌘,** at the bottom of the panel to choose the appearance and language, the menu bar items, alert limits and which cards to show.

## What it does

### Lives in the menu bar

No Dock icon unless you turn it on. The panel opens under the menu bar icon and can be zoomed as a whole. Light and dark appearance, English and Simplified Chinese, launch at login and in-app updates.

### Light on your Mac

Every card reads from one shared sample, taken every 0.3 to 5 seconds. Costly readings slow down or pause while the panel is closed.

### Where the numbers come from

Most readings use public macOS interfaces. Temperatures, fan speed and power draw come from sensors Apple doesn't document, so they can be missing on some Macs. The [data source audit](docs/DATA_SOURCE_AUDIT.md) (in Chinese) lists the source of every number.

## Privacy

- Everything is read on your Mac and stays there. Monitto has no account and no analytics.
- It goes online only to check Monitto's GitHub Releases feed for updates; if that fails, monitoring keeps working.
- Settings are kept in macOS user defaults. The only file Monitto writes is the diagnostics report you export yourself.

## Build from source

You need Xcode 26.6.

```sh
git clone https://github.com/Seaony/Monitto.git
cd Monitto
xcodebuild -project Monitto.xcodeproj -scheme Monitto -configuration Debug \
  -derivedDataPath "$PWD/DerivedData" build
open DerivedData/Build/Products/Debug/Monitto.app
```

See [docs/RELEASING.md](docs/RELEASING.md) for releases.

## Acknowledgements

Updates use [Sparkle](https://sparkle-project.org/).

---

<div align="center">
  <sub>How your Mac is doing, one click away.</sub>
</div>
