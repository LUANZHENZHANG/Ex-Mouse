#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/顺鼠.app"
PLIST_PATH="$APP_PATH/Contents/Info.plist"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/shunshu-dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$ROOT_DIR/scripts/build_app.sh"

if [[ ! -d "$APP_PATH" ]]; then
    echo "Missing app bundle: $APP_PATH"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")
BINARY_PATH="$APP_PATH/Contents/MacOS/MacMousePlus"
ARCHITECTURES="$(lipo -archs "$BINARY_PATH")"

if [[ "$ARCHITECTURES" == *"arm64"* && "$ARCHITECTURES" == *"x86_64"* ]]; then
    ARCH_LABEL="universal"
elif [[ "$ARCHITECTURES" == *"arm64"* ]]; then
    ARCH_LABEL="arm64"
elif [[ "$ARCHITECTURES" == *"x86_64"* ]]; then
    ARCH_LABEL="x86_64"
else
    ARCH_LABEL="${ARCHITECTURES// /-}"
fi

DMG_PATH="$ROOT_DIR/dist/Ex-Mouse-${VERSION}-macOS-${ARCH_LABEL}.dmg"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto --norsrc --noextattr "$APP_PATH" "$STAGING_DIR/顺鼠.app"
xattr -cr "$STAGING_DIR/顺鼠.app"
codesign --force --deep --sign - "$STAGING_DIR/顺鼠.app"
codesign --verify --deep --strict "$STAGING_DIR/顺鼠.app"
ln -s /Applications "$STAGING_DIR/Applications"

cat > "$STAGING_DIR/安装说明.txt" <<'EOF'
顺鼠安装说明

1. 将“顺鼠.app”拖入“Applications”文件夹。
2. 在“应用程序”中找到顺鼠。
3. 首次启动时，右键点击顺鼠并选择“打开”。
4. 按提示授予辅助功能、输入监控和自动化权限。
5. 授权后完全退出顺鼠，再重新启动一次。

顺鼠不联网、不上传数据，也不记录键盘输入。
项目主页：https://github.com/LUANZHENZHANG/Ex-Mouse
EOF

rm -f "$DMG_PATH"
hdiutil create \
    -volname "顺鼠 ${VERSION}" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Built installer: $DMG_PATH"
echo "Architectures: $ARCHITECTURES"
shasum -a 256 "$DMG_PATH"
