# Design: Plugin-based Install Command

**Date:** 2026-05-20  
**Status:** Approved

## Goal

Replace `setup.sh` with a `/claudekit:install` slash command. Users install the plugin then run one command to configure everything. No separate bash script needed.

## What Changes

- `setup.sh` — deleted
- `commands/hooks/setup.md` — deleted (superseded)
- `commands/install.md` — new unified install command
- `README.md` — updated install instructions

## Install Flow

```
/claudekit:install

Step 1 — Scope
  [u] User    → ~/.claude/
  [p] Project → .claude/  (current working directory)

Step 2 — Components (ask each y/n)
  - Settings  (settings.json + statusline-command.sh)
  - Hooks     (ask which: block-prod, auto-lint, audit, slack)
  - MCP       (ask which: AWS, Kubernetes, GitHub + params)
  - Skills    (docling)
  - Rules     (git.md)

Step 3 — Write files at chosen scope path
```

## Scope → Path Mapping

| Component     | User scope           | Project scope        |
|---------------|----------------------|----------------------|
| settings.json | `~/.claude/`         | `.claude/`           |
| hook scripts  | `~/.claude/hooks/`   | `.claude/hooks/`     |
| skills        | `~/.claude/skills/`  | `.claude/skills/`    |
| rules         | `~/.claude/rules/`   | `.claude/rules/`     |

Settings are always merged (not overwritten) — existing keys preserved.

## Implementation Approach

`commands/install.md` is a Claude slash command. Claude executes it as an agentic workflow:

1. Ask scope (user/project) → set `BASE_DIR`
2. Ask each component
3. For each selected component, Claude runs bash to:
   - Create target directories
   - Write script content inline (no plugin dir lookup needed)
   - Merge settings.json via `jq -s '.[0] * .[1]'`
4. For MCP: prompt user for params (profile, region, token var) before writing

Scripts are embedded inline in `install.md` — same content as `scripts/hooks/*.sh`. This avoids fragile plugin-dir path resolution. `scripts/hooks/` stays as reference but `install.md` is authoritative.

## Constraints

- Skills: CC supports both `~/.claude/skills/` and `.claude/skills/`
- MCP servers: only meaningful in user scope (`~/.claude/settings.json`) but install.md allows project scope for team-shared MCP config
- statusline-command.sh: user scope only (it's a shell script, not a Claude config)
- `jq` required — install.md checks prereq and errors clearly if missing

## Success Criteria

- `setup.sh` deleted, no references remain
- `/claudekit:install` installs identical config to what `setup.sh --all` produced
- Scope selection works: user and project paths both correct
- Interactive prompts match current setup.sh behavior
