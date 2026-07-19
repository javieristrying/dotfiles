#!/bin/zsh
# Restore the claudex setup on a fresh machine.
# Recreates: CLIProxyAPI install, its config (with a fresh or existing API key),
# and the background service. The Codex OAuth login must be redone interactively.
set -euo pipefail

DIR="${0:A:h}"
CONF=/opt/homebrew/etc/cliproxyapi.conf

command -v brew >/dev/null || { echo "Homebrew required"; exit 1; }
brew list cliproxyapi >/dev/null 2>&1 || brew install cliproxyapi

if [[ ! -f "$DIR/secret.key" ]]; then
  echo "Generating new proxy API key"
  openssl rand -hex 24 | tr -d '\n' > "$DIR/secret.key"
  chmod 600 "$DIR/secret.key"
fi

sed "s/__CLIPROXY_API_KEY__/$(cat "$DIR/secret.key")/" "$DIR/cliproxyapi.conf.template" > "$CONF"
echo "Wrote $CONF"

brew services restart cliproxyapi
echo
echo "Now log into your ChatGPT/Codex account (opens browser):"
echo "  cliproxyapi --codex-login"
echo
echo "And make sure ~/.zshrc contains:"
echo "  source ~/.config/claudex/claudex.zsh"
