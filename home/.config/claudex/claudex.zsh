# claudex — Claude Code routed through CLIProxyAPI to OpenAI Codex models.
# The proxy API key lives in secret.key (git-ignored), read at invocation time.
alias claudex='ANTHROPIC_BASE_URL=http://127.0.0.1:8317 \
ANTHROPIC_AUTH_TOKEN=$(cat ~/.config/claudex/secret.key) \
CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-terra \
CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
ENABLE_TOOL_SEARCH=false \
claude --model gpt-5.6-sol'
