# dotfiles

Declarative macOS setup built on [Determinate Nix](https://determinate.systems/nix),
[nix-darwin](https://github.com/nix-darwin/nix-darwin), and
[home-manager](https://github.com/nix-community/home-manager). One command takes a
fresh Mac to a fully configured machine: system settings, CLI tools, Homebrew
packages, shell, terminal, editor, and agent skills.

## Setting up a new machine

### Prerequisites

- Admin account (the install and every rebuild use `sudo`)
- Xcode Command Line Tools, needed for `git`:

  ```sh
  xcode-select --install
  ```

Everything else (Nix itself, Homebrew, all packages) is installed by the bootstrap.

### Install

```sh
git clone https://github.com/javieristrying/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./bootstrap.sh
```

`bootstrap.sh` does four things:

1. Installs Determinate Nix (skipped if `nix` is already present)
2. Symlinks the repo to `~/.dotfiles` (config paths resolve through this)
3. Rewrites the `user = "..."` line in `flake.nix` to your macOS username, with confirmation
4. Runs the first `darwin-rebuild switch`

Open a new terminal when it finishes so the Nix-managed shell loads.

On an Intel Mac, change `nixpkgs.hostPlatform` in `configuration.nix` to
`"x86_64-darwin"` before running the bootstrap.

### After the first switch

A few things are account-bound and stay manual:

- `gh auth login` for GitHub
- `nvm install --lts` for Node (nvm comes from Homebrew, but installs no Node version by itself)
- Sign in to Claude Code (`claude`) and Codex (`codex`)

## Day-to-day changes

Edit the config, then apply it:

```sh
./rebuild.sh
```

Homebrew runs with `cleanup = "zap"`: anything installed by hand and not listed
in `configuration.nix` gets removed on the next rebuild. To keep a package, add
it to `brews` or `casks`.

## Layout

| Path | Purpose |
|---|---|
| `flake.nix` | Inputs, the `user` name, and the `mac` host definition |
| `configuration.nix` | System level: macOS defaults, Homebrew packages and casks |
| `home.nix` | User level: CLI packages, zsh, starship, and all symlinks into `$HOME` |
| `home/` | The actual config files the symlinks point at |
| `home/AGENTS.md` | Shared agent instructions, linked to Claude, Codex, and opencode |
| `home/.skills/` | Agent skills, one folder per skill with a `SKILL.md` |
| `bootstrap.sh` | One-time setup for a fresh machine |
| `rebuild.sh` | Applies the current config |

Config symlinks use `mkOutOfStoreSymlink`, so edits to files under `home/`
apply immediately - no rebuild needed. A rebuild is only needed when `.nix`
files change.

## Agent skills

`home/.skills/` is the single store for skills. home-manager links it to every
place agents look:

- `~/.claude/skills` (Claude Code)
- `~/.codex/skills` (Codex)
- `~/.agents/skills` (shared store used by skill installers)

To add a skill, drop a `<name>/SKILL.md` folder into `home/.skills/` and commit.
When installing from a skill repo, copy the inner skill folder out of it rather
than cloning the whole repo in. `home/.skills/.system/` belongs to Codex and is
gitignored.
