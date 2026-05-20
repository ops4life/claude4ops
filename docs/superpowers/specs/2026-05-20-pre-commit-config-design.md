# Pre-commit Config Design

**Date:** 2026-05-20

## Goal

Add `.pre-commit-config.yaml` using the [pre-commit framework](https://pre-commit.com/) to enforce code quality checks locally before commits. Mirrors all checks in `scripts/hooks/pre-commit.sh` and adds gitleaks for secret scanning.

## Hooks

| Hook | Repo / Source | Language | Files matched |
|------|---------------|----------|---------------|
| gitleaks | `gitleaks/gitleaks` (upstream) | golang | all |
| shellcheck | `shellcheck-py/shellcheck-py` (upstream) | python | `*.sh` |
| yamllint | `adrienverge/yamllint` (upstream) | python | `*.yaml`, `*.yml` |
| validate-commands | local → `scripts/test/validate-commands.sh` | script | `^commands/.*\.md$` |
| test-update-plugin-version | local → `node scripts/test/test-update-plugin-version.js` | node | `update-plugin-version\.js$` |

## Config structure

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: <pinned>
    hooks:
      - id: gitleaks

  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: <pinned>
    hooks:
      - id: shellcheck

  - repo: https://github.com/adrienverge/yamllint
    rev: <pinned>
    hooks:
      - id: yamllint
        args: ["-d", "relaxed"]

  - repo: local
    hooks:
      - id: validate-commands
        name: Validate command frontmatter
        entry: scripts/test/validate-commands.sh
        language: script
        files: ^commands/.*\.md$
        pass_filenames: false

      - id: test-update-plugin-version
        name: JS unit tests
        entry: node scripts/test/test-update-plugin-version.js
        language: node
        files: update-plugin-version\.js$
        pass_filenames: false
```

Upstream revs pinned to latest stable at time of creation. Kept current via `pre-commit autoupdate`.

## CI integration

Add a `pre-commit` job to `.github/workflows/ci.yaml` that runs `pre-commit run --all-files`. This covers gitleaks on every PR (not currently checked in CI) and validates the config stays working. Existing individual jobs (shellcheck, test-js, validate-commands) remain — they provide clearer failure signals per check.

## Files changed

- `.pre-commit-config.yaml` — new file
- `.github/workflows/ci.yaml` — add `pre-commit` job

## Out of scope

- Removing `scripts/hooks/pre-commit.sh` — kept for standalone CI/manual use
- Removing existing CI jobs — pre-commit CI job is additive
