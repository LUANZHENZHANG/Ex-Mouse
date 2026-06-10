#!/bin/zsh
set -euo pipefail

PLIST_DST="$HOME/Library/LaunchAgents/com.zhangzeliang.macmouseplus.plist"
SYSTEM_EXECUTABLE="/Applications/顺鼠.app/Contents/MacOS/MacMousePlus"
USER_EXECUTABLE="$HOME/Applications/顺鼠.app/Contents/MacOS/MacMousePlus"

if [[ -x "$SYSTEM_EXECUTABLE" ]]; then
    APP_EXECUTABLE="$SYSTEM_EXECUTABLE"
elif [[ -x "$USER_EXECUTABLE" ]]; then
    APP_EXECUTABLE="$USER_EXECUTABLE"
else
    APP_EXECUTABLE=""
fi

if [[ -z "$APP_EXECUTABLE" ]]; then
    echo "Missing installed app executable."
    echo "Run ./scripts/install_app.sh first."
    exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zhangzeliang.macmouseplus</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_EXECUTABLE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_DST" >/dev/null 2>&1 || true
launchctl load "$PLIST_DST"
echo "Installed LaunchAgent: $PLIST_DST"
