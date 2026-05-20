# Token Optimization Install Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add RTK and Caveman as an "Optimization" component (item 6) in `/claudekit:install`, with sub-selection between the two tools.

**Architecture:** All changes are confined to `commands/install.md` — the agentic install prompt. Three sections change: Step 3 menu gains item 6, Step 4 gains an Optimization install block with sub-selection and warn-and-continue error handling, Step 5 summary gains an Optimization line.

**Tech Stack:** Markdown (LLM prompt template), bash snippets embedded in the prompt, `curl`, `claude` CLI.

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Modify | `commands/install.md` | Step 3 menu, Step 4 Optimization block, Step 5 summary |

No new files. No test files (validate-commands.sh tests frontmatter only — no functional testing for prompt content).

---

### Task 1: Add item 6 to the Step 3 component selection menu

**Files:**
- Modify: `commands/install.md` (lines 44–61)

- [ ] **Step 1: Verify current menu text**

Run:
```bash
grep -n "5. Rules" /opt/claudekit/commands/install.md
```
Expected: one match showing the line number of `  5. Rules     — git workflow rules`

- [ ] **Step 2: Add item 6 to menu and update `a` description**

In `commands/install.md`, replace:

```
  5. Rules     — git workflow rules
  a. All

Enter numbers and/or 'a', separated by spaces (e.g. 1 3 5 or a):
```

With:

```
  5. Rules        — git workflow rules
  6. Optimization — RTK (token-efficient shell proxy) + Caveman mode plugin
  a. All

Enter numbers and/or 'a', separated by spaces (e.g. 1 3 5 or a):
```

Also update the bullet below the menu block from:

```
- Input includes `a` → select all 5 components; skip all sub-selection prompts in Step 4 and use defaults for any required values
```

To:

```
- Input includes `a` → select all 6 components; Optimization sub-selection still shown (only 2 tools, quick)
```

- [ ] **Step 3: Run validation to confirm frontmatter still valid**

```bash
bash /opt/claudekit/scripts/test/validate-commands.sh
```
Expected: `OK: all command files have valid frontmatter`

- [ ] **Step 4: Commit**

```bash
git add commands/install.md
git commit -m "feat: add Optimization to install component menu"
```

---

### Task 2: Add Optimization install block to Step 4

**Files:**
- Modify: `commands/install.md` (after the Rules section, before Step 5)

- [ ] **Step 1: Locate insertion point**

Run:
```bash
grep -n "^## Step 5" /opt/claudekit/commands/install.md
```
Expected: one match, e.g. `459:## Step 5 — Summary`

The new Optimization section goes immediately before that line (after the `---` separator that ends Rules).

- [ ] **Step 2: Insert Optimization section**

Add the following block immediately before `## Step 5 — Summary` (after the closing `---` of the Rules section):

````markdown
### Optimization

Present sub-selection:

```
Which optimization tools? (select all that apply)
  1. RTK     — token-efficient shell command proxy (60-90% token savings)
  2. Caveman — ultra-compressed communication mode (~75% token savings)
  a. All

Enter numbers and/or 'a':
```

#### RTK

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

If curl or install script fails, print:
> `RTK install failed — skipping. Install manually: https://github.com/rtk-ai/rtk`
Then continue.

On success, patch PATH for bash and zsh:

```bash
for rc in ~/.bashrc ~/.zshrc; do
  [ -f "$rc" ] || continue
  grep -q 'HOME/.local/bin' "$rc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
```

Wire Claude Code hook (use full path — shell not yet reloaded):

```bash
~/.local/bin/rtk init -g --auto-patch
```

If `rtk init` fails, print:
> `RTK hook setup failed — run ~/.local/bin/rtk init -g --auto-patch manually after reloading your shell`
Then continue.

#### Caveman

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

If either command fails, print:
> `Caveman install failed — skipping. Install manually: claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman`
Then continue.

---
````

- [ ] **Step 3: Run validation**

```bash
bash /opt/claudekit/scripts/test/validate-commands.sh
```
Expected: `OK: all command files have valid frontmatter`

- [ ] **Step 4: Commit**

```bash
git add commands/install.md
git commit -m "feat: add Optimization install block (RTK + Caveman) to install wizard"
```

---

### Task 3: Update Step 5 summary template

**Files:**
- Modify: `commands/install.md` (Step 5 summary block)

- [ ] **Step 1: Locate summary block**

Run:
```bash
grep -n "Rules.*git.md" /opt/claudekit/commands/install.md
```
Expected: match inside the Step 5 summary code block.

- [ ] **Step 2: Add Optimization line to summary**

In the summary code block, replace:

```
  ✓ Rules     → git.md   ($BASE/rules/)

Restart Claude Code to apply changes.
```

With:

```
  ✓ Rules        → git.md   ($BASE/rules/)
  ✓ Optimization → RTK (~/.local/bin/rtk), Caveman plugin

Restart Claude Code to apply changes.
```

And update the trailing note from:

```
Only list components that were actually installed.
```

To (no change needed — this instruction already handles partial Optimization installs):

```
Only list components that were actually installed. For Optimization, only list tools that succeeded.
```

- [ ] **Step 3: Run validation**

```bash
bash /opt/claudekit/scripts/test/validate-commands.sh
```
Expected: `OK: all command files have valid frontmatter`

- [ ] **Step 4: Commit**

```bash
git add commands/install.md
git commit -m "feat: add Optimization to install summary output"
```
