#!/usr/bin/env bash
# Takes a fresh machine from nothing to a built config.
# Run this once. After it finishes, use ./rebuild.sh for packages and macOS defaults.
# Edits to files under home/ apply immediately - no rebuild.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Homebrew"
if command -v brew >/dev/null 2>&1; then
  echo "    brew already installed, skipping"
else
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Step 2: rustup"
if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
  echo "    rustup already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

echo "==> Step 3: symlink this repo to ~/.dotfiles and link home files"
"$DIR/link.sh"

echo "==> Step 4: packages from Brewfile"
brew bundle install --file="$DIR/Brewfile"

if [[ "$(uname -s)" = Darwin ]]; then
  echo "==> Step 5: macOS defaults"
  "$DIR/macos.sh"
else
  echo "==> Step 5: skip macOS defaults (not Darwin)"
  echo "    To make zsh your login shell: chsh -s \$(command -v zsh)"
fi

echo "==> Done. Open a new terminal."
echo "    Then, if this is a new machine: gh auth login, nvm install --lts, sign in to claude/codex"
