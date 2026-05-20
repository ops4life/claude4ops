---
description: DevOps-focused PR review - Terraform, secrets, containers, pipeline security
---

# PR Review - DevOps Focused

Run a structured PR review covering infrastructure, security, and pipeline concerns. Base branch passed as argument (default: `main`).

## Usage

`/claude4ops:cicd:pr-review` with optional base branch argument (e.g. `main`, `develop`)

## Requirements

**User must provide:**
- Base branch to diff against (default: `main` if not specified)

## Review Steps

Run ALL steps in order. Do not skip any step.

### Step 1 - Get the Diff

```bash
git diff origin/$ARGUMENTS...HEAD
```

Read ALL changed files. Note every file type present in the diff.

### Step 2 - Terraform Changes

For any `.tf` or `.tfvars` files:

1. Run `terraform validate` in each changed module directory
2. Flag resources missing required tags (`Environment`, `Team`, `CostCenter`)
3. Flag unencrypted storage resources (S3 buckets, RDS, EBS volumes without encryption)
4. Flag S3 buckets missing versioning or access logging
5. Flag IAM policies with `*` actions or `*` resources (overly permissive)
6. Flag `terraform apply` without `-var-file` for environment-specific configs
7. Flag secrets or sensitive values hardcoded in `.tfvars` (use AWS Secrets Manager data sources instead)

### Step 3 - Dockerfile / Container Changes

For any `Dockerfile` or container-related changes:

1. Flag base images pinned to `:latest` — require digest pinning (e.g. `image@sha256:...`)
2. Flag `COPY . .` without a `.dockerignore` in the same directory
3. Flag secrets or credentials hardcoded as `ENV` variables
4. Flag running as root user (missing `USER` directive)
5. Flag missing `HEALTHCHECK` instruction
6. Flag multiple `RUN` layers that could be combined to reduce image size

### Step 4 - CI/CD Pipeline Changes

For any GitHub Actions (`.github/workflows/`), GitLab CI (`.gitlab-ci.yml`), or other pipeline files:

1. Flag missing `permissions` blocks on GitHub Actions jobs (default is overly permissive)
2. Flag stored `GITHUB_TOKEN` secrets that could use OIDC federation instead
3. Flag `actions/checkout` without `persist-credentials: false` where credentials aren't needed
4. Flag pinning actions by branch name instead of commit SHA (supply chain risk)
5. Flag missing `timeout-minutes` on jobs (runaway jobs consume quota)
6. Flag `continue-on-error: true` on security or test steps

### Step 5 - Secrets Scan

Scan the entire diff for hardcoded secrets using these patterns:
- AWS access keys: `AKIA[A-Z0-9]{16}`
- AWS secret keys: `[0-9a-zA-Z/+]{40}`
- Generic API tokens: `(api_key|api_token|secret|password)\s*[=:]\s*['"][a-zA-Z0-9]{16,}`
- Private keys: `-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----`
- Connection strings: `(mongodb|postgresql|mysql)://[^@]+:[^@]+@`

Flag ANY match as a critical blocker.

### Step 6 - Kubernetes Manifests

For any `.yaml` files that appear to be K8s manifests:

1. Flag missing `resources.limits` on containers
2. Flag missing `readinessProbe` or `livenessProbe`
3. Flag `privileged: true` in security contexts
4. Flag `hostNetwork: true` or `hostPID: true`
5. Flag images without digest pinning

## Output Format

```
### PR Review Summary
**Branch:** <branch name>
**Base:** <base branch>
**Files changed:** <count>

### Critical Issues (block merge)
- [file:line] Issue description

### Warnings (fix before merge)
- [file:line] Issue description

### Suggestions (optional improvements)
- [file:line] Suggestion

### Verdict: APPROVE / REQUEST CHANGES / NEEDS WORK
```

## Best Practices

- Run this before picking up a new ticket to understand what's already in flight
- Combine with MCP server access to validate live AWS/K8s state against the diff
- Use the secrets scan output to drive secret rotation if a match is found
- Share the structured report directly in the PR as a review comment
