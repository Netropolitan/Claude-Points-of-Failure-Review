# /pof — Points of Failure Review for Claude Code

A Claude Code skill that spawns two independent AI reviewers in parallel — Claude and OpenAI Codex — to audit your completed work for real points of failure. Two models, two perspectives, one combined report.

## How It Works

```
You complete a task
        |
        v
   /pof — gather git diff + changed files
        |
        v
   Two reviewers run in PARALLEL
        |
   Claude Agent ──────── Codex Agent
   (Anthropic)           (OpenAI gpt-5.3-codex)
        |                      |
        v                      v
   Findings              Findings
        |                      |
        └──────────┬───────────┘
                   |
                   v
   Deduplicated, synthesised report
   with recommended actions
```

Both reviewers independently examine the same diff looking for:

| Category | What They Check |
|----------|----------------|
| **Logic errors** | Off-by-one, wrong conditionals, race conditions, null checks |
| **Security issues** | SQL injection, XSS, command injection, missing auth, IDOR |
| **Missing error handling** | Unhandled API failures, DB errors, file operations |
| **Data integrity** | Missing validation, non-atomic state updates, constraint gaps |
| **Edge cases** | Empty lists, missing keys, Unicode, boundary values, concurrency |
| **Integration failures** | API contract mismatches, missing migrations, broken imports |
| **Deployment risks** | Missing env vars, migration ordering, breaking changes |
| **Performance traps** | N+1 queries, unbounded loops, missing pagination, missing indexes |

Findings from both reviewers are deduplicated and cross-referenced. Issues flagged by **both** models get higher confidence. The orchestrator adds its own assessment on top.

## Prerequisites

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** with the Agent tool available
- **[OpenAI Codex CLI](https://github.com/openai/codex)** installed and authenticated (via ChatGPT Plus/Pro subscription)

If Codex isn't available, the skill degrades gracefully — Claude's review runs alone and you still get a useful report.

## Installation

### Quick Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/Netropolitan/AI-Text-Tools/main/claude-skills/pof/install.sh | bash
```

This downloads the skill and places it in `~/.claude/skills/pof/`. Restart Claude Code after running it.

### Manual Install

#### 1. Install the Skill

```bash
# Create the skill directory
mkdir -p ~/.claude/skills/pof

# Copy the skill file
cp skill/SKILL.md ~/.claude/skills/pof/SKILL.md
```

Or if you cloned this repo:

```bash
cp -r skill/ ~/.claude/skills/pof/
```

#### 2. Verify

Start a new Claude Code session and type `/pof` — you should see the skill activate and begin gathering context.

### Uninstall

```bash
rm -rf ~/.claude/skills/pof
```

## Usage

Invoke `/pof` after completing any piece of work:

### After a feature

```
/pof
```

### With context

```
/pof
Just finished the new notification system — review the backend changes
```

### After a bug fix

```
/pof
Review the fix I just made to the auth middleware
```

## Output Format

The report groups findings by severity and shows which reviewer(s) found each issue:

```
## Points of Failure Review

### Task: Add user notification system
### Files reviewed: 8 files changed

### Findings

#### Critical (1)
- [POF-001] SQL injection in notification query — backend/notifications.py:42
  Found by: Claude + Codex
  Risk: User-controlled input concatenated into SQL query
  Fix: Use parameterised queries

#### High (2)
- [POF-002] Missing auth check on DELETE endpoint — backend/routes.py:87
  Found by: Claude only
  ...

### Summary
- Total findings: 5
- Agreement (both flagged): 2
- Claude-only: 2
- Codex-only: 1

### Recommended Actions
1. Fix POF-001 immediately (SQL injection)
2. Add auth middleware to new routes (POF-002)
3. ...
```

## How It Differs from a Code Review

This isn't a style review or a "clean code" audit. It specifically looks for **things that will break** — in production, under load, with bad input, during deployment, or at integration boundaries. If the code is solid, the report says so. No manufactured findings.

## Guardrails

- **Read-only** — never modifies files, only reads and analyses
- **Focused on the diff** — reviews what changed, not the entire codebase
- **Honest** — a clean report is a valid outcome; no padding
- **Codex-resilient** — works with Claude alone if Codex is unavailable

## License

MIT License. See [LICENSE](LICENSE) for details.
