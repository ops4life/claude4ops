---
name: claude4ops:convert
description: Convert Claude Code artifacts (CLAUDE.md, hooks, Anthropic SDK) to equivalent configs for other AI tools — Gemini CLI, GitHub Copilot, Cursor, or OpenAI Codex. Always fetches current docs via context7 before generating any output.
---

# Convert Claude Code Workflows to Other AI Tools

Convert Claude Code artifacts — `CLAUDE.md`, hooks, Anthropic SDK code — to equivalent configs for Gemini CLI, GitHub Copilot, Cursor, or OpenAI Codex.

## When to Apply

Trigger when the user:
- Says "convert to Gemini", "migrate to Copilot", "port to Cursor", "translate to Codex/OpenAI"
- Wants to replicate their Claude Code setup in another AI coding tool
- Has Anthropic SDK code they want to migrate to another provider

## Workflow

### Step 1: Detect Claude Artifacts

Scan the project for Claude-specific artifacts:

```bash
# Config files
ls CLAUDE.md .claude/CLAUDE.md .claude/settings.json .claude/settings.local.json 2>/dev/null

# Hooks
ls .claude/hooks/ 2>/dev/null

# Anthropic SDK usage
grep -r "from anthropic\|import anthropic\|@anthropic-ai/sdk\|Anthropic()" \
  --include="*.py" --include="*.ts" --include="*.js" . 2>/dev/null | head -20
```

Report what was found before proceeding.

### Step 2: Identify Target Tool

If not specified, ask:

> Which tool would you like to convert to?
> 1. Google Gemini CLI
> 2. GitHub Copilot
> 3. Cursor
> 4. OpenAI Codex

### Step 3: Fetch Current Docs via context7

**REQUIRED — never skip, never use training-data guesses.**

Fetch current documentation using context7 before generating any config or SDK translation:

**Gemini CLI:**
```
mcp__plugin_context7_context7__resolve-library-id: "gemini cli"
mcp__plugin_context7_context7__query-docs: config format, GEMINI.md, system prompts, settings.json
```

**GitHub Copilot:**
```
mcp__plugin_context7_context7__resolve-library-id: "github copilot"
mcp__plugin_context7_context7__query-docs: copilot-instructions.md format, custom instructions
```

**Cursor:**
```
mcp__plugin_context7_context7__resolve-library-id: "cursor"
mcp__plugin_context7_context7__query-docs: .cursorrules format, cursor rules, .cursor/rules
```

**OpenAI Codex / AGENTS.md:**
```
mcp__plugin_context7_context7__resolve-library-id: "openai"
mcp__plugin_context7_context7__query-docs: AGENTS.md format, openai SDK chat completions
```

Cite the resolved library ID and doc version in every generated file header.

### Step 4: Generate Target Configs

#### Step 4a: Resolve `@file` imports

Inline `@file` imports for every target that lacks import support. Re-running `/convert` is the sync mechanism: one command refreshes every target config.

**Gemini CLI follows `@file.md` imports itself** (documented as "memport", nested imports included; see the context7 `/google-gemini/gemini-cli` docs fetched in Step 3). For a Gemini target, do not inline:

- Rewrite each in-repo `@path` in `CLAUDE.md` to `@./path`, relative to the generated `GEMINI.md`. Add no wrapper markers.
- Still apply rule 3 (outside the repo root: skip with a marker) and rule 4 (missing file: `<!-- UNRESOLVED @path -->`, no dangling import).
- Leave imported files unedited, including their own nested imports. Gemini's import detection (`findImports` in `memoryImportProcessor.ts`) accepts an `@` followed by `.`, `/` or a letter, so bare `@path` imports work as well as `@./path`; do not inline them. It matches `@` after any whitespace, not only at the start of a line, so stray `@name` text in an imported file may be tried as an import; report nothing and edit nothing (Gemini's behaviour on an unresolvable match is not verified).
- Re-check the docs: if they no longer show `@` imports, inline as for other targets.

Copilot, Cursor and Codex have no verified import support: inline for them.

1. Find `@path` tokens in `CLAUDE.md`. Ignore any inside fenced code blocks or inline code.
2. Resolve each path relative to the file that contains it (`~` expands to the home directory).
3. **Outside the repo root** (including `~` paths): do not inline. Warn and leave `<!-- SKIPPED (outside repo) @path -->`. Personal files must not leak into a committed config.
4. **Missing or unreadable file**: warn and continue. Leave `<!-- UNRESOLVED @path -->`. Never halt the conversion for one bad import.
5. Otherwise read the file and apply steps 1-4 to it (nested imports), up to 5 hops deep. Past 5, leave `<!-- UNRESOLVED @path (max depth) -->`.
6. Keep the set of files already inlined on the current import chain. A file importing one of its ancestors is not re-inlined: leave `<!-- skipped: cycle @path -->`.
7. Wrap each inlined file's content, with its nested imports already resolved:

```
<!-- inlined from .claude/rules/git.md -->
...content...
<!-- end .claude/rules/git.md -->
```

Use repo-relative paths in the markers. Put no timestamps inside inlined blocks, so a re-run diffs only when a rule changed.

Collect every UNRESOLVED, SKIPPED and cycle marker for the Step 6 summary.

#### CLAUDE.md → Target Config

Write the resolved content from Step 4a (inlined, or rewritten `@./path` imports for Gemini; not the raw `@` lines):

| Claude artifact | Gemini CLI | GitHub Copilot | Cursor | OpenAI Codex |
|---|---|---|---|---|
| `CLAUDE.md` | `GEMINI.md` | `.github/copilot-instructions.md` | `.cursorrules` | `AGENTS.md` |
| `.claude/settings.json` hooks | `.gemini/settings.json` | ⚠️ No equivalent | `.cursor/rules/` | ⚠️ No equivalent |

Add a header comment to every generated file:

```
# Generated by /claude4ops:convert
# Source: CLAUDE.md
# Target: [Tool Name]
# Docs: context7 [library-id] — fetched [date]
# Review before committing. Claude-specific sections marked ⚠️.
```

Keep the original `CLAUDE.md` intact — generate new files alongside, never overwrite.

#### Anthropic SDK → Target SDK

For each file with Anthropic SDK imports, output a side-by-side migration:

**Python — Anthropic → Google Generative AI (Gemini):**
```python
# BEFORE (Anthropic)
import anthropic
client = anthropic.Anthropic()
message = client.messages.create(
    model="claude-opus-4-8",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}]
)
print(message.content[0].text)

# AFTER (google-generativeai)
import google.generativeai as genai
import os
genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel("gemini-2.0-flash")  # adjust model as needed
response = model.generate_content("Hello")
print(response.text)
```

**Python — Anthropic → OpenAI (Copilot / Codex):**
```python
# BEFORE (Anthropic)
import anthropic
client = anthropic.Anthropic()
message = client.messages.create(
    model="claude-opus-4-8",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}]
)
print(message.content[0].text)

# AFTER (openai)
from openai import OpenAI
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4o",  # adjust model as needed
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}]
)
print(response.choices[0].message.content)
```

**TypeScript — Anthropic → OpenAI:**
```typescript
// BEFORE
import Anthropic from "@anthropic-ai/sdk";
const client = new Anthropic();
const msg = await client.messages.create({
  model: "claude-opus-4-8",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});
console.log(msg.content[0].text);

// AFTER
import OpenAI from "openai";
const client = new OpenAI();
const response = await client.chat.completions.create({
  model: "gpt-4o",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});
console.log(response.choices[0].message.content);
```

**Model name mapping (approximate):**

| Anthropic | Gemini | OpenAI |
|---|---|---|
| claude-opus-4-x (most capable) | gemini-2.0-pro | gpt-4o |
| claude-sonnet-4-x (balanced) | gemini-2.0-flash | gpt-4o-mini |
| claude-haiku-4-x (fastest) | gemini-2.0-flash-lite | gpt-4o-mini |

Always verify model availability against current docs fetched from context7.

#### Step 4b: Gemini `.gemini/settings.json` (permissions and MCP servers)

Gemini target only. Source is the committed `.claude/settings.json`; never read `.claude/settings.local.json` (personal). If the source is missing or has no `permissions` or `mcpServers`, skip this step and write nothing. Field names come from the Step 3 docs; re-check them there.

**Never emit `tools.core`.** It is an allowlist for all built-in tools, so it would disable `read_file`, `grep_search` and the rest.

1. `permissions.allow` → `tools.allowed` (tools that skip the confirmation prompt). `Bash(cmd *)` and `Bash(cmd:*)` become `run_shell_command(cmd)` (Gemini matches by prefix). An exact `Bash(cmd args)` becomes `run_shell_command(cmd args)`. Anything else (a wildcard in the middle, non-Bash tools) is unmapped.
2. `permissions.deny` is unmapped (`tools.exclude` is deprecated in favour of the Policy Engine).
3. `mcpServers` → `mcpServers`. Stdio keeps `command`, `args`, `env`, `cwd`. `type: http` becomes `httpUrl`, `type: sse` becomes `url`; keep `headers`. Never set `trust`.
4. Secrets: a value already written as `$VAR` or `${VAR}` stays as is. `${VAR:-default}` becomes `$VAR` (report the dropped default). A literal `env` or `headers` value becomes `$<KEY>` (the key name, upper case); report it so the user sets that variable to the full original value (including any prefix such as `Bearer `).
5. JSON has no comments: list every unmapped or rewritten entry, with the reason, in the Step 6 summary.

**Never overwrite or modify an existing `.gemini/settings.json`:**

- No `.gemini/settings.json` yet: write it.
- It exists: leave it untouched. Write `.gemini/settings.generated.json` instead (replaced on each run), then print `diff -u .gemini/settings.json .gemini/settings.generated.json`, or "no differences". The user merges by hand; merging `tools.allowed` automatically could widen their confirmation bypass unreviewed.

#### Step 4c: PLAYBOOKS.md from skills

Claude Code skills are multi-step checklists with no equivalent in other tools. Flatten them into one plain-markdown `PLAYBOOKS.md` that any tool can read. Run this once per conversion: the output is the same for every target. Skills only; do not process `commands/`.

1. **Find skills:** `.claude/skills/*/SKILL.md`. When the project root has `.claude-plugin/`, also `skills/*/SKILL.md`. A skill directory that resolves outside the repo root (a symlink) is skipped with a warning. If none are found, skip this step: write nothing and add no pointer line.
2. **One section per skill**, in directory order:
   - `## <name>` from the frontmatter `name`
   - `**When to use:**` followed by the frontmatter `description`
   - `Source: <repo-relative path to SKILL.md>`
   - the SKILL.md body below the frontmatter, **verbatim**, with every heading demoted two levels (ignore `#` lines inside code fences). Do not summarize, reorder or rewrite prose into numbered steps.
3. **References stay links.** Rewrite relative links such as `references/x.md` to repo-relative paths so they resolve from the repo root. Never inline the referenced file. Keep a link whose target is missing and report it.
4. **Claude-only constructs** (`mcp__*` tool names, the Skill tool, `AskUserQuestion`, `${CLAUDE_*}`): keep the text and add one line `⚠️ Claude Code only: [what was found]` to the section.
5. **Script-driven skills** (the skill directory contains a `scripts/` directory): write only the title, "When to use", `Source:` and `⚠️ script-driven, not flattened`.
6. **Write** `PLAYBOOKS.md` at the repo root next to the target config, starting with `<!-- Generated by /claude4ops:convert from .claude/skills; do not edit -->`. Put no timestamp in it, so a re-run diffs only when a skill changed. If a `PLAYBOOKS.md` already exists without that first line, leave it untouched and write `PLAYBOOKS.generated.md` instead.
7. **Pointer line:** add to every generated target config the single line `Runbooks for multi-step tasks are in PLAYBOOKS.md; read it only when asked to perform one.` Plain text: never an `@` import and never inlined, so the playbooks are not loaded every session.

#### Hook Mappings

| Claude Code hook | Gemini CLI | Copilot | Cursor | Codex |
|---|---|---|---|---|
| `PreToolUse` (block commands) | `.gemini/settings.json` extensions | ⚠️ No equivalent | Cursor Rules | ⚠️ No equivalent |
| `Stop` (auto-lint) | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent |
| `PostToolUse` (audit log) | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent |
| Notification hooks (Slack) | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent | ⚠️ No equivalent |

### Step 5: Flag Unsupported Features

For every Claude feature with no equivalent, include a warning block in the generated output:

```
⚠️  UNSUPPORTED: Claude Code hooks (PreToolUse / Stop / PostToolUse)
    These run shell scripts at tool-call boundaries. [Target] has no equivalent.
    Workaround: Use git hooks (pre-commit) or CI pipeline steps instead.

⚠️  UNSUPPORTED: Tool-use permissions (allowedTools / blockedTools)
    Claude Code's fine-grained tool permission system has no direct equivalent.
    Workaround: Document rules in the target config file as natural-language instructions.
    (Gemini CLI: allow rules are translated by Step 4b; only unmapped entries and deny rules remain unsupported.)

⚠️  UNSUPPORTED: MCP server configuration
    MCP is Claude Code-specific. Some tools support OpenAPI/function calling instead.
    Workaround: Expose your MCP server via OpenAPI spec and register as a tool/function.
    (Gemini CLI: servers are translated by Step 4b.)

⚠️  UNSUPPORTED: claude4ops plugin skills and commands
    These are Claude Code-only. No equivalent exists in other tools.
    Skills are partly covered by PLAYBOOKS.md (Step 4c); commands are not converted.
```

### Step 6: Output Summary

After generating all files, print:

```
Conversion complete: Claude Code → [Target Tool]
Docs fetched: context7 [library-id] (fetched [date])

Generated:
  ✓ [target config file]       ← from CLAUDE.md
  ✓ [sdk-migration.md]         ← Anthropic SDK migration notes

Imports: [N] inlined (or [N] kept as native @./ imports for Gemini), [N] unresolved, [N] skipped (outside repo), [N] cycles
  ⚠️  unresolved: [@path ...]   (omit lines with none)
  ⚠️  skipped (outside repo): [@path ...]

Playbooks: [N] skills flattened to PLAYBOOKS.md (or PLAYBOOKS.generated.md), [N] script-driven, [N] with Claude-only notes
  ⚠️  broken reference links: [path ...]   (omit when none)

Settings (Gemini only): wrote .gemini/settings.json | existing file untouched, wrote .gemini/settings.generated.json
  [diff -u output, or "no differences"]
  ⚠️  unmapped or rewritten: [entry: reason ...]   (omit when none)

Warnings ([N] features with no equivalent):
  ⚠️  hooks → no equivalent in [target tool]
  ⚠️  MCP servers → no equivalent (see workaround above)
  ⚠️  tool permissions → no equivalent

Review all generated files before committing.
Source files were not modified.
```

## Notes

- Never generate target configs without first fetching context7 docs — formats change
- Resolve `@file` imports in CLAUDE.md (Step 4a: inline, except Gemini keeps native `@./` imports) before mapping content to target format; re-run `/convert` after any rule change to sync all targets
- `PLAYBOOKS.md` is only pointed to from each config by one plain line, never imported or inlined; an existing hand-written `PLAYBOOKS.md` is never overwritten
- Source files (`CLAUDE.md`, SDK files) are read-only — generate new files alongside. Never modify an existing `.gemini/settings.json`
- For multi-target conversions, run Steps 3–6 once per target tool
- If context7 cannot resolve a library, warn the user and halt rather than guessing
