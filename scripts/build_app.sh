#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
OUTPUT_APP_DIR="$ROOT_DIR/dist/顺鼠.app"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/shunshu-app.XXXXXX")"
APP_DIR="$TEMP_DIR/顺鼠.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
ICON_FILE="$RESOURCES_DIR/AppIcon.icns"
REPO_ICON_FILE="$ROOT_DIR/assets/AppIcon.png"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
swift build -c release

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/MacMousePlus" "$MACOS_DIR/MacMousePlus"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

if [[ -f "$REPO_ICON_FILE" ]]; then
  sips -z 16 16 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$REPO_ICON_FILE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
else
  swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$ICONSET_DIR"
fi

iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacMousePlus</string>
    <key>CFBundleIdentifier</key>
    <string>com.zhangzeliang.macmouseplus</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleDisplayName</key>
    <string>顺鼠</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>Ex-Mouse</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.15</string>
    <key>CFBundleVersion</key>
    <string>115</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/MacMousePlus"
xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

rm -rf "$OUTPUT_APP_DIR"
mkdir -p "$(dirname "$OUTPUT_APP_DIR")"
ditto --norsrc --noextattr "$APP_DIR" "$OUTPUT_APP_DIR"
codesign --verify --deep --strict "$OUTPUT_APP_DIR"
echo "Built app bundle at: $OUTPUT_APP_DIR"
