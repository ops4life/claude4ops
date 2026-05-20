---
description: Full agentic pipeline - review, test, commit, push with safety gates
---

# Ship Command - Full CI/CD Pipeline

Run the entire ship workflow autonomously: safety checks → static analysis → tests → staged commit → push. One command, one human confirmation gate before irreversible steps.

## Usage

`/claude4ops:cicd:ship` with commit message as argument (e.g. `feat(payments): add redis cache layer`)

## Requirements

**User must provide:**
- Commit message following conventional commits format
- Confirmation at the staged commit step before push

## Pipeline Steps

### Step 1 - Safety Checks

1. Confirm current branch is NOT `main` or `master`. Abort immediately if so with message: "Refusing to ship directly from main/master. Create a feature branch first."
2. Run `git status` — if untracked files exist, list them and ask the user to confirm before continuing.
3. Run `git diff --stat HEAD` and summarise what's staged.

### Step 2 - Static Analysis

Run ALL of the following for each applicable file type in the diff:

**Secrets scan** — scan diff for:
- AWS keys (`AKIA[A-Z0-9]{16}`)
- Generic tokens (`token\s*=\s*['"][a-zA-Z0-9]{20,}`)
- Passwords (`password\s*=\s*['"][^'"]{8,}`)
- If found: **STOP immediately and report**. Do not continue.

**Linting** — run for each file type present:
- `*.py` → `ruff check` and `black --check`
- `*.tf` → `tflint` and `terraform validate` in each changed module directory
- `*.go` → `golangci-lint run`
- `*.ts` / `*.js` → `eslint`
- `*.yaml` / `*.yml` → `yamllint`

**Terraform-specific** (if any `.tf` files changed):
- Run `terraform validate` in each changed module directory
- Flag resources missing required tags: `Environment`, `Team`, `CostCenter`
- Flag missing encryption, versioning, or access logging on storage resources

If any check fails: show the full output and stop. Do NOT proceed to tests.

### Step 3 - Tests

Detect and run the appropriate test command:
1. Check for `Makefile` with `test` target → `make test`
2. Check for `pytest.ini` or `pyproject.toml` → `pytest`
3. Check for `go.mod` → `go test ./...`
4. Check for `package.json` with test script → `npm test`

If tests fail: show failures clearly and stop. Do NOT proceed.

### Step 4 - Staged Commit (Human Gate)

1. Show `git diff --stat HEAD` summary
2. **WAIT for explicit user confirmation ("yes" or "y") before proceeding**
3. On confirmation:
   ```bash
   git add -A
   git commit -m "$ARGUMENTS

   Changes:
   $(git diff --stat HEAD)"
   ```

### Step 5 - Push

```bash
git push -u origin HEAD
```

Output the branch URL and suggest next step: open a PR.

## Headless / CI Mode

Run non-interactively from a shell script or git alias:

```bash
# Git alias in ~/.gitconfig
[alias]
  ship = !claude --print "/claude4ops:cicd:ship $1"
```

```bash
# CI usage
RESULT=$(claude --print "/claude4ops:cicd:ship feat(api): add rate limiting" 2>&1)
EXIT=$?
```

## Safety Rules

- Never run on `main` or `master` — abort immediately
- Never skip the human confirmation gate at Step 4
- Never continue past a failed secrets scan, linter error, or test failure
- Always show full error output before stopping
- Treat `exit 2` from PreToolUse hooks as a hard block — surface the message to the user

## Best Practices

- Use conventional commit format: `type(scope): description`
- Keep commits atomic — one logical change per ship
- Wire a PreToolUse hook to block prod targets before running this command
- Add a Stop hook to auto-format files after each Claude turn
