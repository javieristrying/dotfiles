# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `brew bundle install --force-cleanup --zap` in `rebuild.sh` is intentional. It forces the good habit of declaring every Homebrew package in the Brewfile instead of installing things ad-hoc, which keeps the machine reproducible. Do not drop `--zap` or `--force-cleanup`. Users are warned about its effect in README.md; this note is for anyone tempted to change the setting itself.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
