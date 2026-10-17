export EDITOR=nvim

# Homebrew
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# rustup
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Vite+ bin (https://viteplus.dev)
. "/Users/javier/.config/vite-plus/env"
