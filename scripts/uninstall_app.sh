#!/bin/zsh
set -euo pipefail

SYSTEM_TARGET_APP="/Applications/顺鼠.app"
USER_TARGET_APP="$HOME/Applications/顺鼠.app"

rm -rf "$SYSTEM_TARGET_APP" "$USER_TARGET_APP"
echo "Removed app bundles: $SYSTEM_TARGET_APP $USER_TARGET_APP"
