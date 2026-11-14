# 发版配置，由共用脚本 ~/.agents/skills/mac-release/scripts/mac-release 读取，变量说明见同目录的 SKILL.md。
# 默认用 Developer ID 签名并公证，Sparkle 私钥和 CodeEdge、Diskit 共用钥匙串里的 com.seaony.Moni。
APP_NAME=Monitto
release_validate() { scripts/validate-release.sh "$1" "${2:-}"; }
# 带背景图和固定图标布局的安装窗口，配置见 scripts/dmg/
DMG_SETTINGS=scripts/dmg/dmg-settings.py
