#!/usr/bin/env bash
# Point $HOME at the files in home/. Safe to re-run.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"
DOT="$HOME/.dotfiles/home"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$dest" && ! -L "$dest" ]]; then
    echo "refusing to replace directory: $dest" >&2
    exit 1
  fi
  ln -sfn "$src" "$dest"
  echo "  $dest -> $src"
}

echo "==> linking dotfiles"

link "$DOT/.zshenv" "$HOME/.zshenv"
link "$DOT/.zshrc" "$HOME/.zshrc"
link "$DOT/.config/starship.toml" "$HOME/.config/starship.toml"
link "$DOT/.config/wezterm" "$HOME/.config/wezterm"
link "$DOT/.config/nvim" "$HOME/.config/nvim"
link "$DOT/.config/herdr" "$HOME/.config/herdr"
link "$DOT/.config/claudex" "$HOME/.config/claudex"
link "$DOT/.config/ghostty" "$HOME/.config/ghostty"
link "$DOT/.claude/settings.json" "$HOME/.claude/settings.json"
link "$DOT/.skills" "$HOME/.claude/skills"
link "$DOT/.skills" "$HOME/.codex/skills"
link "$DOT/.skills" "$HOME/.agents/skills"
link "$DOT/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$DOT/AGENTS.md" "$HOME/.codex/AGENTS.md"
link "$DOT/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

if [[ "$(uname -s)" = Darwin ]]; then
  # Ghostty on macOS also reads this path. Same file as ~/.config/ghostty/config.
  link "$DOT/.config/ghostty/config" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  # Old filename from before the XDG layout. Same file, so edits cannot split.
  link "$DOT/.config/ghostty/config" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
fi

echo "==> done"
