# claudex

Claude Code routed to OpenAI Codex models (`gpt-5.6-sol` main, `gpt-5.6-terra`
at medium effort for subagents) through a local
[CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) instance.
Based on [thsottiaux's tweet](https://x.com/thsottiaux/status/2076119366647894371).

## How it works

- CLIProxyAPI runs as a Homebrew service on `127.0.0.1:8317`, speaking the
  Anthropic Messages API and forwarding to OpenAI using a Codex OAuth credential.
- The `claudex` alias points Claude Code at the proxy via `ANTHROPIC_BASE_URL`
  and authenticates with a local shared secret (`secret.key`).
- Subagent effort: a `payload.override` rule in the proxy config forces
  `reasoning.effort: medium` on all `gpt-5.6-terra` requests. Effort-suffixed
  model names (`gpt-5.6-terra-medium`) are NOT supported by the Codex OAuth
  channel; the override runs after the proxy's thinking mapper, so it wins over
  whatever thinking budget Claude Code sends.

## Files

| File | Purpose |
|---|---|
| `cliproxyapi.conf.template` | Proxy config with `__CLIPROXY_API_KEY__` placeholder; deployed to `/opt/homebrew/etc/cliproxyapi.conf` |
| `claudex.zsh` | The `claudex` alias; sourced from `~/.zshrc` |
| `secret.key` | Proxy API key (git-ignored, chmod 600) — local shared secret between Claude Code and the proxy |
| `restore.sh` | Recreates the whole setup on a fresh machine |

Not stored here (and must never be): the Codex OAuth credential
(`~/.cli-proxy-api/codex-<email>.json`) — it contains a refresh token with
standing access to the ChatGPT account. Recreate it with `cliproxyapi --codex-login`.

## Restore on a new machine

```sh
~/.config/claudex/restore.sh
cliproxyapi --codex-login
```

## Maintenance

- Config changes: edit the template, re-run `restore.sh` (or edit
  `/opt/homebrew/etc/cliproxyapi.conf` directly and re-sanitize into the
  template). The proxy hot-reloads config; `brew services restart cliproxyapi`
  if in doubt.
- Rotate the key: delete `secret.key`, run `restore.sh`.
