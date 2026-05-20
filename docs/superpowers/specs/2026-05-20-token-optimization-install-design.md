# Token Optimization Tools — Install Design

**Date:** 2026-05-20
**Scope:** Add RTK + Caveman as installable components in `/claude4ops:install`

---

## Summary

Add a new **Optimization** category (item 6) to the `/claude4ops:install` component selection menu. It bundles two token-reduction tools — RTK and Caveman — each selectable independently via sub-selection.

---

## Component Selection Menu Change

Step 3 gains a 6th item:

```
  6. Optimization — RTK (token-efficient shell proxy) + Caveman mode plugin
```

- `a` (all) includes Optimization and proceeds to its sub-selection prompt.
- Selecting `6` alone also shows the sub-selection prompt.

---

## Sub-Selection Prompt

```
Which optimization tools? (select all that apply)
  1. RTK     — token-efficient shell command proxy (60-90% savings)
  2. Caveman — ultra-compressed communication mode (~75% savings)
  a. All

Enter numbers and/or 'a':
```

---

## Install Steps

### RTK

Install via universal shell script (works on Linux and macOS, installs to `~/.local/bin`):

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

Patch PATH if not already present (bash and zsh):

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

**On failure:** print warning `RTK install failed — skipping. Install manually: https://github.com/rtk-ai/rtk` and continue to next tool.

### Caveman

Install as Claude plugin:

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

**On failure:** print warning `Caveman install failed — skipping` and continue.

---

## Summary Output (Step 5)

When Optimization is installed, append to the summary:

```
  ✓ Optimization → RTK (~/.local/bin/rtk), Caveman plugin
```

Only list tools that actually succeeded.

---

## Error Handling

| Failure | Behavior |
|---------|----------|
| curl unavailable | Warn, skip RTK |
| rtk install script fails | Warn, skip RTK |
| `claude` CLI not in PATH | Warn, skip Caveman |
| `claude plugin` commands fail | Warn, skip Caveman |

All failures are non-fatal — remaining components continue installing.

---

## Files Changed

- `commands/install.md` — add item 6 to Step 3 menu, add Optimization section to Step 4, update Step 5 summary template
