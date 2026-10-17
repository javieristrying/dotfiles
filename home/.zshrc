typeset -U path cdpath fpath manpath

bindkey -e
WORDCHARS=${WORDCHARS//\/}

autoload -U compinit && compinit

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
unsetopt APPEND_HISTORY EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST \
  HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

if [[ -n "${HOMEBREW_PREFIX:-}" && -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
ZSH_AUTOSUGGEST_STRATEGY=(history)
bindkey '^f' autosuggest-accept

if [[ $TERM != dumb ]] && command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

[[ -f "$HOME/.config/claudex/claudex.zsh" ]] && source "$HOME/.config/claudex/claudex.zsh"

export NVM_DIR="$HOME/.nvm"
[[ -d "$NVM_DIR" ]] || mkdir -p "$NVM_DIR"
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  [[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  [[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi

path=("$HOME/.opencode/bin" $path)

alias ..='cd ..'
alias add='git add .'
alias push='git push'
alias pull='git pull'
alias msg='git commit -am'
alias gst='git status'
alias m='git switch main'
alias cc='claude --dangerously-skip-permissions'
alias co='codex --full-auto'

if [[ -n "${HOMEBREW_PREFIX:-}" && -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
fi

# >>>> BEGIN MANAGED DEVIN BLOCK >>>>
# Add ~/.local/bin to PATH for devin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
# <<<< END MANAGED DEVIN BLOCK <<<<

# Vite+ bin (https://viteplus.dev)
. "/Users/javier/.config/vite-plus/env"

# Added by Devin
export PATH="/Users/javier/.codeium/windsurf/bin:$PATH"
