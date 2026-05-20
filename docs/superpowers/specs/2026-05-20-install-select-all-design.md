# Design: Select-All Option in /claudekit:install

**Date:** 2026-05-20
**File changed:** `commands/install.md`

## Problem

Step 3 of `/claudekit:install` asks yes/no for each of 5 components individually. No way to install everything without answering 5+ prompts.

## Solution

Replace per-component yes/no prompts with a numbered multi-select checklist. Add `a` (All) as the last option at each selection level.

## Step 3 — Component Selection (new format)

Claude presents:

```
Which components do you want to install? (select all that apply)

  1. Settings  — settings.json merge + status line script
  2. Hooks     — lifecycle hooks (block-prod, auto-lint, audit, Slack)
  3. MCP       — AWS, Kubernetes, GitHub real API access
  4. Skills    — docling (PDF/DOCX/image → Markdown)
  5. Rules     — git workflow rules
  a. All

Enter numbers and/or 'a', separated by spaces (e.g. 1 3 5 or a):
```

- Input includes `a` → select all 5 components
- Input is numbers → select only those components
- Invalid input → re-prompt

## Sub-selections (Hooks and MCP)

When Hooks is selected, present:

```
Which hooks? (select all that apply)
  1. block-prod   — PreToolUse: blocks prod-targeting commands
  2. auto-lint    — Stop: formats files Claude touched after each turn
  3. audit-bash   — PostToolUse: logs all Bash commands
  4. slack-notify — Notification: posts Claude alerts to Slack
  a. All

Enter numbers and/or 'a':
```

When MCP is selected, present:

```
Which MCP servers? (select all that apply)
  1. AWS
  2. Kubernetes
  3. GitHub
  a. All

Enter numbers and/or 'a':
```

## Select-All Cascade

If user selects `a` at the top-level component prompt, skip all sub-selection prompts. Install all hooks and all MCP servers using default values:

| MCP / Hook param     | Default              |
|----------------------|----------------------|
| AWS profile          | `dev`                |
| AWS region           | `us-east-1`          |
| Kubeconfig path      | `~/.kube/config`     |
| GitHub token env var | `GITHUB_TOKEN`       |

Slack hook: still inform the user that `SLACK_WEBHOOK` env var must be set, even in the all-install path.

## Scope

- Only `commands/install.md` changes.
- Install logic (Step 4) unchanged — it already installs whatever was selected.
- Step 5 summary format unchanged.
