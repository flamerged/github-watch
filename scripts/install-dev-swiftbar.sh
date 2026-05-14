#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PLUGIN="$ROOT/bin/github-watch.5m.sh"
TARGET_DIR="${1:-$HOME/SwiftBarPlugins}"
TARGET="$TARGET_DIR/github-watch.5m.sh"

if [[ ! -f "$PLUGIN" || ! -r "$PLUGIN" ]]; then
  print -u2 "plugin source not found or unreadable: $PLUGIN"
  exit 1
fi

mkdir -p "$TARGET_DIR"
ln -sf "$PLUGIN" "$TARGET"
chmod +x "$PLUGIN"

print "installed dev symlink $TARGET -> $PLUGIN"
