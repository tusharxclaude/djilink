#!/bin/sh
# Builds djilink from source into ~/.local/bin. Optionally installs a login agent.
# Env: DJILINK_REF (git ref, default main), DJILINK_AGENT=1 to install the login agent,
#      DJILINK_KEYCODE (default 49), DJILINK_FLAGS (default option)
set -eu

REPO="${DJILINK_REPO:-tusharxclaude/djilink}"
REF="${DJILINK_REF:-main}"
BIN_DIR="$HOME/.local/bin"
LABEL="com.djilink"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

[ "$(uname)" = "Darwin" ] || { echo "djilink only works on macOS." >&2; exit 1; }
command -v swiftc >/dev/null 2>&1 || {
  echo "swiftc not found. Install the Command Line Tools: xcode-select --install" >&2
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/djilink.swift" -o "$tmp/djilink.swift"
mkdir -p "$BIN_DIR"
swiftc -O "$tmp/djilink.swift" -o "$BIN_DIR/djilink"
echo "Installed $BIN_DIR/djilink"

if [ "${DJILINK_AGENT:-0}" = "1" ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN_DIR/djilink</string>
    <string>--keycode</string><string>${DJILINK_KEYCODE:-49}</string>
    <string>--flags</string><string>${DJILINK_FLAGS:-option}</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>/tmp/djilink.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  echo "Login agent installed ($PLIST)"
fi

cat <<EOF

Next:
  1. Run: $BIN_DIR/djilink --list     (confirm your receiver shows up)
  2. Run: $BIN_DIR/djilink            (default: Link -> Option+Space)
  3. Approve the Accessibility and Input Monitoring prompts in
     System Settings > Privacy & Security.
  To run at login: DJILINK_AGENT=1 sh install.sh
EOF
