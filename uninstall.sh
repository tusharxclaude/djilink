#!/bin/sh
set -u
LABEL="com.djilink"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/.local/bin/djilink"
echo "djilink removed."
