#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/pof"
SKILL_URL="https://raw.githubusercontent.com/Netropolitan/AI-Text-Tools/main/claude-skills/pof/skill/SKILL.md"

echo "Installing /pof skill for Claude Code..."

# 1. Create skill directory and download SKILL.md
mkdir -p "$SKILL_DIR"

if command -v curl &>/dev/null; then
  curl -fsSL "$SKILL_URL" -o "$SKILL_DIR/SKILL.md"
elif command -v wget &>/dev/null; then
  wget -qO "$SKILL_DIR/SKILL.md" "$SKILL_URL"
else
  echo "Error: curl or wget is required to install."
  exit 1
fi

echo "  Skill installed to $SKILL_DIR/SKILL.md"

echo ""
echo "Done! Restart Claude Code, then use /pof to get started."
echo ""
echo "Prerequisites:"
echo "  - Claude Code with Agent tool support"
echo "  - OpenAI Codex CLI (optional — skill works without it)"
echo "    Install: https://github.com/openai/codex"
