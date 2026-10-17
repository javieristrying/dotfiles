#!/usr/bin/env bash
# One-time: detach Homebrew from nix-homebrew, then uninstall nix-darwin and Determinate Nix.
# Requires sudo. Delete this file after it succeeds.
set -euo pipefail

# This environment often has no TTY. Honor SUDO_ASKPASS (macOS GUI dialog).
if [[ -n "${SUDO_ASKPASS:-}" ]]; then
  sudo() { command sudo -A "$@"; }
fi

if [[ "$(uname -s)" != Darwin ]]; then
  echo "uninstall-nix.sh is macOS only" >&2
  exit 1
fi

PREFIX="/opt/homebrew"
USER_NAME="$(id -un)"
GROUP_NAME="admin"

restore_homebrew() {
  echo "==> restoring standalone Homebrew into $PREFIX (Cellar/Caskroom kept)"

  if [[ -x "$PREFIX/bin/brew" && ! -L "$PREFIX/bin/brew" ]] &&
     [[ -d "$PREFIX/Library/Homebrew" && ! -L "$PREFIX/Library/Homebrew" ]] &&
     [[ -d "$PREFIX/.git" ]]; then
    echo "    brew is already a real checkout, skipping restore"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d /tmp/homebrew-restore.XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN

  git clone --depth=1 https://github.com/Homebrew/brew "$tmp/brew"

  # nix-homebrew owns these as root-owned store symlinks
  if [[ -L "$PREFIX/bin/brew" ]]; then
    sudo rm -f "$PREFIX/bin/brew"
  fi
  if [[ -L "$PREFIX/Library/Homebrew" ]]; then
    sudo rm -f "$PREFIX/Library/Homebrew"
  fi
  if [[ -e "$PREFIX/Library/.homebrew-is-managed-by-nix" ]]; then
    sudo rm -rf "$PREFIX/Library/.homebrew-is-managed-by-nix"
  fi

  sudo cp "$tmp/brew/bin/brew" "$PREFIX/bin/brew"
  sudo chmod 755 "$PREFIX/bin/brew"
  sudo rm -rf "$PREFIX/Library/Homebrew"
  sudo cp -R "$tmp/brew/Library/Homebrew" "$PREFIX/Library/Homebrew"
  sudo rm -rf "$PREFIX/.git"
  sudo cp -R "$tmp/brew/.git" "$PREFIX/.git"

  for f in completions manpages docs CHANGELOG.md LICENSE.txt README.md; do
    if [[ -e "$tmp/brew/$f" ]]; then
      sudo rm -rf "$PREFIX/$f"
      sudo cp -R "$tmp/brew/$f" "$PREFIX/$f"
    fi
  done

  sudo chown -R "$USER_NAME:$GROUP_NAME" \
    "$PREFIX/bin/brew" \
    "$PREFIX/Library/Homebrew" \
    "$PREFIX/.git"

  unset HOMEBREW_REPOSITORY
  if ! "$PREFIX/bin/brew" --version >/dev/null; then
    echo "    brew --version failed after restore" >&2
    exit 1
  fi
  if [[ -L "$PREFIX/bin/brew" ]]; then
    echo "    $PREFIX/bin/brew is still a symlink; restore did not take" >&2
    exit 1
  fi
  echo "    brew is now $($PREFIX/bin/brew --version | head -n1)"
}

echo "==> Step 1: standalone Homebrew (must happen while Nix still exists)"
restore_homebrew

if [[ -x /run/current-system/sw/bin/darwin-uninstaller ]]; then
  echo "==> Step 2: uninstall nix-darwin"
  # darwin-rebuild activate inside the uninstaller must run as root.
  printf 'y\n' | sudo /run/current-system/sw/bin/darwin-uninstaller
else
  echo "==> Step 2: nix-darwin uninstaller not found, skipping"
fi

# Deactivation may have removed the brew we just restored.
restore_homebrew

if [[ -x /nix/nix-installer ]]; then
  echo "==> Step 3: uninstall Determinate Nix"
  # Must be root already; the installer re-execs sudo without our askpass.
  sudo /nix/nix-installer uninstall --no-confirm
elif [[ -x /nix/lix-installer ]]; then
  echo "==> Step 3: uninstall Lix/Nix"
  sudo /nix/lix-installer uninstall --no-confirm
else
  echo "==> Step 3: nix-installer not found, skipping"
fi

if [[ -f /etc/synthetic.conf ]] && grep -qx nix /etc/synthetic.conf; then
  echo "==> Step 5: drop leftover /etc/synthetic.conf nix line"
  sudo sed -i '' '/^nix$/d' /etc/synthetic.conf
fi
if [[ -d /etc/nix ]]; then
  echo "==> Step 5: remove leftover /etc/nix"
  sudo rm -rf /etc/nix
fi

echo "==> Step 4: verify brew still works"
"$PREFIX/bin/brew" --version

echo "==> Done. Open a new terminal."
echo "    Check: echo \$PATH | tr ':' '\\n' | grep nix"
echo "    Expect: no output. Then delete this file."
