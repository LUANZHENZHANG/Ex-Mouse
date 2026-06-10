#!/bin/zsh
set -euo pipefail

PLIST_DST="$HOME/Library/LaunchAgents/com.zhangzeliang.macmouseplus.plist"

launchctl unload "$PLIST_DST" >/dev/null 2>&1 || true
rm -f "$PLIST_DST"
echo "Removed LaunchAgent: $PLIST_DST"
