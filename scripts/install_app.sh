#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/dist/顺鼠.app"
SYSTEM_INSTALL_DIR="/Applications"
USER_INSTALL_DIR="$HOME/Applications"
APP_NAME="顺鼠.app"

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "Missing app bundle: $SOURCE_APP"
    echo "Run ./scripts/build_app.sh first."
    exit 1
fi

TARGET_APP=""
if [[ -w "$SYSTEM_INSTALL_DIR" ]]; then
    TARGET_APP="$SYSTEM_INSTALL_DIR/$APP_NAME"
else
    mkdir -p "$USER_INSTALL_DIR"
    TARGET_APP="$USER_INSTALL_DIR/$APP_NAME"
fi

rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"
xattr -cr "$TARGET_APP"
codesign --force --deep --sign - "$TARGET_APP" >/dev/null

echo "Installed app bundle at: $TARGET_APP"
