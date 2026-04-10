---
name: pof
description: Points of Failure review — spawns Claude and Codex agents in parallel to audit completed work for mistakes, bad code, edge cases, and potential failures.
---

# Points of Failure (POF) Review

A post-task audit that spawns two independent reviewers — a Claude Code agent and an OpenAI Codex agent — to examine completed work from different angles. Both agents analyse the same changes and report back their findings, giving you two independent perspectives on what could go wrong.

## When to Use

Invoke `/pof` after completing a task — a feature, bug fix, refactor, or any meaningful code change — to get a second (and third) opinion before moving on.

## Workflow

```
/pof invoked
      |
      v
  Gather context
  (git diff, changed files, recent commits)
      |
      v
  Spawn two reviewers in PARALLEL
      |
  Claude Agent ──────── Codex Agent
  (general-purpose)     (gpt-5.3-codex)
      |                      |
      v                      v
  Findings              Findings
      |                      |
      └──────────┬───────────┘
                 |
                 v
  Synthesise & present combined report
  with recommended actions
```

## Step-by-Step Execution

### Step 1: Gather Context

Before spawning reviewers, collect what was changed:

1. Run `git diff HEAD~5 --stat` to see recently changed files (adjust range based on the task scope — use `git log --oneline -10` to find the right starting commit for the current task)
2. Run `git diff HEAD~5` for the full diff of changes (again, adjust range to match the task)
3. Run `git log --oneline -10` for recent commit messages to understand the narrative
4. If the task scope is unclear, look at the conversation history to determine which commits relate to the just-completed work

Identify:
- **Changed files**: The files that were modified, added, or deleted
- **Task summary**: A one-line description of what was just done
- **Scope**: Which parts of the codebase were touched

### Step 2: Spawn Reviewers in Parallel

Spawn **both agents simultaneously** using parallel tool calls.

#### Claude Reviewer (Agent tool, subagent_type: `general-purpose`)

Prompt must include:
- The full git diff of changes
- The list of changed files
- A summary of what the task was meant to accomplish

Instruction:
```
You are a code reviewer performing a "Points of Failure" audit on recently completed work.

Your job is to find things that could go wrong — not style nits or theoretical improvements, but real points of failure:

1. **Logic errors**: Off-by-one, wrong conditionals, race conditions, missing null checks where data could actually be null
2. **Missing error handling**: API calls without error handling, database operations that could fail, file operations without existence checks — but only where failure is realistic
3. **Security issues**: SQL injection, XSS, command injection, exposed secrets, missing auth checks, IDOR vulnerabilities
4. **Data integrity**: Missing validation, inconsistent state updates, transactions that should be atomic but aren't
5. **Edge cases**: Empty lists, missing keys, concurrent access, Unicode/encoding issues, boundary values
6. **Integration failures**: API contract mismatches, missing migrations, broken imports, dependency version conflicts
7. **Deployment risks**: Missing environment variables, Docker build issues, migration ordering, backwards-incompatible changes
8. **Performance traps**: N+1 queries, unbounded loops, missing pagination, large payload responses, missing indexes

For each finding, report:
- **Severity**: Critical / High / Medium / Low
- **File and line**: Where the issue is
- **What could go wrong**: The specific failure scenario
- **Suggested fix**: How to address it (be specific)

If the code looks solid, say so. Don't manufacture findings. A clean report is a valid outcome.

Report your findings as a structured list grouped by severity.
```

#### Codex Reviewer (Bash tool — codex exec)

Build and run the Codex command:

```bash
codex exec --skip-git-repo-check -m gpt-5.3-codex --config model_reasoning_effort="xhigh" --sandbox read-only 2>/dev/null "You are performing a 'Points of Failure' audit on recently completed code changes.

Here are the changed files: [LIST FILES]

Review these changes and identify real points of failure — things that could break in production, edge cases, security issues, logic errors, missing error handling, data integrity problems, and deployment risks.

For each finding report:
- Severity (Critical/High/Medium/Low)
- File and location
- What could go wrong
- Suggested fix

Focus on real, actionable issues. If the code is solid, say so. Don't manufacture findings."
```

**Important Codex notes:**
- Always use `--skip-git-repo-check` and `2>/dev/null`
- Default to `--sandbox read-only` — this is a review, not a code change
- Use `gpt-5.3-codex` with `xhigh` reasoning effort
- The Codex command runs in the project's working directory so it has access to all files

### Step 3: Synthesise and Present

Once both agents have reported back:

1. **Deduplicate**: If both found the same issue, merge into one finding and note that both reviewers flagged it (higher confidence)
2. **Assess agreement**: Where they agree, confidence is higher. Where only one flags something, note which reviewer found it
3. **Sort by severity**: Critical first, then High, Medium, Low
4. **Present the combined report**:

```
## Points of Failure Review

### Task: [what was done]
### Files reviewed: [count] files changed

### Findings

#### Critical (X)
- **[POF-001]** [Title] — [file:line]
  Found by: Claude + Codex | Claude only | Codex only
  Risk: [what could go wrong]
  Fix: [suggested fix]

#### High (X)
...

#### Medium (X)
...

#### Low (X)
...

### Summary
- Total findings: X
- Agreement (both flagged): X
- Claude-only: X
- Codex-only: X
- Clean areas: [parts of the code both reviewers found solid]

### Recommended Actions
1. [Action items in priority order]
```

5. **Give your own assessment**: After presenting findings from both reviewers, add your own take — do you agree with the findings? Are any overblown? Did both miss something you noticed? Be honest and direct.

## Guardrails

- **Read-only operation.** This skill only reads and analyses code. It never modifies files.
- **No manufactured findings.** If the code is solid, say "clean review - no significant points of failure found." Don't pad the report.
- **Be specific.** "This could fail" is useless. "Line 42 in routes.py: the `user_id` parameter is passed directly to the SQL query without parameterisation - SQL injection risk" is useful.
- **Focus on the diff.** Review what changed, not the entire codebase. Pre-existing issues are out of scope unless the new changes interact with them.
- **Respect Codex output critically.** Codex is a peer reviewer, not an authority. Evaluate its findings against your own understanding. Flag disagreements.
- **Don't block on Codex failure.** If the Codex command fails (auth issues, timeout, etc.), report Claude's findings alone and note that Codex was unavailable. The review still has value with one reviewer.

## Example Invocations

### After completing a feature
```
/pof
```

### With specific scope hint
```
/pof
Just finished the new email notification system - review the backend changes
```

### After a bug fix
```
/pof
Review the fix I just made to the auth middleware
```
