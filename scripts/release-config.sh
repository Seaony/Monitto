# 发版配置，由共用脚本 ~/.agents/skills/mac-release/scripts/mac-release 读取，变量说明见同目录的 SKILL.md。
APP_NAME=Moni
SIGNING=adhoc
NOTES_FOOTER='此构建未使用 Apple Developer ID 签名，也未经过 Apple 公证。首次打开时，macOS 可能阻止运行；请在“系统设置 → 隐私与安全性”中确认打开。'
release_validate() { scripts/validate-release.sh "$1" "${2:-}"; }
# 带背景图和固定图标布局的安装窗口，配置见 scripts/dmg/
DMG_SETTINGS=scripts/dmg/dmg-settings.py
