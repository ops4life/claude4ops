# Contributing to claude4ops

claude4ops is a community-driven toolkit. Contributions are welcome from everyone—developers, operators, and anyone passionate about automating and improving software delivery through DevOps principles.

## Quick Start

```bash
# 1. Fork the repo on GitHub, then clone your fork
git clone https://github.com/<your-username>/claude4ops.git
cd claude4ops

# 2. Create a feature branch
git checkout -b feat/my-new-command

# 3. Make your changes (see workflow below)

# 4. Commit using conventional commits format
git commit -m "feat(cicd): add rollback command"

# 5. Push and open a PR
git push origin feat/my-new-command
```

## What to Contribute

- **New commands** — workflows for DevOps domains not yet covered
- **Command improvements** — better examples, additional cloud providers, edge case handling
- **Bug fixes** — incorrect guidance, broken examples, typos
- **Documentation** — clearer explanations, additional context

Check [open issues](https://github.com/ops4life/claude4ops/issues) for ideas.

## Command Structure

Commands are Markdown files in `commands/<category>/`. Each follows this structure:

```markdown
---
description: Clear, concise description (under 80 chars)
---

# Command Title

Brief intro explaining what this command does and when to use it.

## Requirements

What the user must provide or have set up before running this command.

## Workflow

Step-by-step procedure. Use numbered steps for sequential actions.
Include code blocks for commands. Cover AWS, GCP, and Azure where applicable.

## Output Format

Template or example of what the command produces.

## Best Practices

Security, reliability, and operational guidance relevant to this domain.
```

Existing commands: `commands/k8s/deploy.md`, `commands/terraform/plan-review.md`, `commands/cicd/ship.md`.

## Worked Example: Adding a New Command

Let's add `commands/cicd/rollback.md` — a guided rollback workflow.

**1. Identify the category.** This is a CI/CD workflow, so it belongs in `commands/cicd/`.

**2. Create the file.**

```bash
touch commands/cicd/rollback.md
```

**3. Write the command.**

```markdown
---
description: Guided rollback to a previous deployment with verification
---

# Rollback Command

Roll back a failed deployment by reverting to the last known-good version,
with pre-checks, execution, and post-rollback verification.

## Requirements

**User must provide:**
- Target service name and namespace (Kubernetes) or stack name (Terraform/ECS)
- The target version or commit to roll back to (or "previous" for auto-detect)

## Workflow

### Step 1 - Identify Rollback Target

1. Run `git log --oneline -10` to show recent commits.
2. If user said "previous", identify the commit before the last deployment tag.
3. Confirm target version with user before proceeding.

### Step 2 - Pre-Rollback Checks

Check current health:
- **Kubernetes**: `kubectl rollout status deployment/<name> -n <namespace>`
- **ECS**: `aws ecs describe-services --cluster <cluster> --services <service>`
- **GCP Cloud Run**: `gcloud run services describe <service> --region <region>`

### Step 3 - Execute Rollback

**Kubernetes:**
```bash
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace> --timeout=5m
```

**ECS (previous task definition):**
```bash
aws ecs update-service --cluster <cluster> --service <service> \
  --task-definition <task-def>:<previous-revision>
```

**Terraform (via git revert):**
```bash
git revert <commit-sha>
terraform plan   # review before applying
terraform apply
```

### Step 4 - Verify Rollback

1. Check pod/task health (repeat Step 2 checks).
2. Tail logs for 60 seconds: `kubectl logs -f deployment/<name> -n <namespace>`
3. Report: rollback version, health status, any warnings.

## Best Practices

- Always verify target version before executing — a rollback to the wrong version makes things worse.
- Keep rollback confirmation as a human gate for production environments.
- After rollback stabilizes, open a postmortem with `/claude4ops:incident:postmortem`.
```

**4. Test it.** Install the plugin from local source and run the command:

```
/plugin marketplace add /absolute/path/to/claude4ops
/plugin install claude4ops
/claude4ops:cicd:rollback
```

Verify the workflow is coherent and the command exits cleanly.

**5. Commit.**

```bash
git add commands/cicd/rollback.md
git commit -m "feat(cicd): add guided rollback command

Supports Kubernetes, ECS, and Terraform rollback with pre-checks
and post-rollback verification."
```

## Commit Format

claude4ops uses [Conventional Commits](https://www.conventionalcommits.org/) for automated releases:

| Prefix | Effect | Example |
|--------|--------|---------|
| `feat(scope):` | Minor version bump | `feat(k8s): add drain-node command` |
| `fix(scope):` | Patch version bump | `fix(terraform): correct cost estimate formula` |
| `docs:` | No release | `docs: improve rollback examples` |
| `chore:` | No release | `chore: update dependencies` |
| `feat!:` or `BREAKING CHANGE:` | Major version bump | `feat!: redesign command invocation` |

Scope is the category name: `k8s`, `terraform`, `cicd`, `observability`, `incident`, `hooks`.

Full release details: [.github/RELEASING.md](.github/RELEASING.md).

## Pull Request Process

1. Fill out the PR template — it takes 2 minutes and helps reviewers.
2. One logical change per PR. Split unrelated changes.
3. PRs merge to `main`. Releases are automatic via semantic-release — no manual tagging needed.
4. A maintainer will review within a few days. If no response in a week, ping in the issue.

## Standards

- **No hardcoded secrets or credentials** in commands or examples.
- **Multi-cloud coverage** — include AWS, GCP, and Azure examples where the workflow differs.
- **Safety first** — include validation, pre-checks, and rollback steps in any deployment command.
- **No AI attribution** — keep output clean and professional. No "Generated with Claude Code" signatures.
- **Professional tone** — commands are production tooling, not tutorials.

## Project Structure

```
commands/           # Command Markdown files by category
  k8s/              # Kubernetes operations
  terraform/        # Infrastructure as Code
  cicd/             # CI/CD pipelines and deployment
  observability/    # Monitoring, alerting, SLOs
  incident/         # Incident response
  hooks/            # Hooks and MCP configuration
scripts/            # Hook scripts installed to ~/.claude/
skills/             # Claude Code skills
rules/              # Global rules
```

## Questions

Open an issue or start a discussion on GitHub.
