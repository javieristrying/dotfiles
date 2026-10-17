#!/usr/bin/env bash
# Re-link home files, install Brewfile packages, zap anything not listed, apply macOS defaults.
# Config files under home/ are live via symlink - you do not need this to edit .zshrc.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

"$DIR/link.sh"

if ! command -v brew >/dev/null 2>&1; then
  echo "brew not on PATH. Run ./bootstrap.sh first." >&2
  exit 1
fi

brew bundle install --file="$DIR/Brewfile" --force-cleanup --zap

if [[ "$(uname -s)" = Darwin ]]; then
  "$DIR/macos.sh"
fi
