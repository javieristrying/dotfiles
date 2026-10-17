# dotfiles

Home files live in `home/` and get symlinked into `$HOME`. Homebrew installs the packages. No Nix.

## Setting up a new machine

### Prerequisites

- Admin account (Homebrew's installer may ask for it)
- Xcode Command Line Tools, needed for `git` and Homebrew:

  ```sh
  xcode-select --install
  ```

### Install

```sh
git clone https://github.com/javieristrying/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./bootstrap.sh
```

`bootstrap.sh` does five things:

1. Installs Homebrew (skipped if `brew` is already present)
2. Installs rustup (skipped if `~/.cargo/bin/rustup` exists)
3. Symlinks this repo to `~/.dotfiles` and links everything under `home/`
4. Installs the Brewfile
5. On macOS, writes system defaults (dark mode, key repeat, dock, finder, tap to click)

Open a new terminal when it finishes.

### After the first run

A few things are account-bound and stay manual:

- `gh auth login` for GitHub
- `nvm install --lts` for Node (nvm comes from Homebrew, but installs no Node version by itself)
- Sign in to Claude Code (`claude`) and Codex (`codex`)

## Day-to-day changes

Edit the file under `home/`. It is already the live file via symlink. No rebuild.

To add or remove a package, edit `Brewfile`, then:

```sh
./rebuild.sh
```

`rebuild.sh` runs `brew bundle --force-cleanup --zap`: anything installed by hand and not listed in `Brewfile` gets removed. To keep a package, add it to the Brewfile.

To change macOS defaults, edit `macos.sh` and run `./rebuild.sh` (or `./macos.sh` directly).

## Linux

Same repo, same `bootstrap.sh`. Homebrew-on-Linux covers the packages. `macos.sh` is skipped. To use zsh as your login shell afterwards: `chsh -s $(command -v zsh)`.

## Layout

| Path | Purpose |
|---|---|
| `home/` | The actual config files the symlinks point at |
| `home/.zshrc` | Shell: aliases, nvm, plugins, starship |
| `home/.zshenv` | `EDITOR`, Homebrew, rustup - loaded for every zsh |
| `home/.config/` | wezterm, ghostty, nvim, herdr, claudex, starship |
| `home/AGENTS.md` | Shared agent instructions, linked to Claude, Codex, and opencode |
| `home/.skills/` | Agent skills, one folder per skill with a `SKILL.md` |
| `Brewfile` | Homebrew formulae, casks, fonts |
| `link.sh` | Creates the `~/.dotfiles` symlink and every home link |
| `macos.sh` | macOS `defaults write` |
| `bootstrap.sh` | One-time setup for a fresh machine |
| `rebuild.sh` | Re-link, brew bundle with zap, macOS defaults |

## Agent skills

`home/.skills/` is the single store for skills. `link.sh` links it to every place agents look:

- `~/.claude/skills` (Claude Code)
- `~/.codex/skills` (Codex)
- `~/.agents/skills` (shared store used by skill installers)

To add a skill, drop a `<name>/SKILL.md` folder into `home/.skills/` and commit.
When installing from a skill repo, copy the inner skill folder out of it rather than cloning the whole repo in. `home/.skills/.system/` belongs to Codex and is gitignored.
