# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claudekit** is a comprehensive Claude Code plugin for DevOps, SRE, and Platform Engineering workflows. It provides production-ready slash commands for infrastructure management, deployment automation, observability, and incident response across multi-cloud environments (AWS, GCP, Azure).

**Purpose**: Enhance DevOps productivity with guided workflows, best practices, and automated procedures for:
- Kubernetes operations and troubleshooting
- Infrastructure as Code (Terraform) management
- CI/CD pipeline creation and deployment strategies
- Monitoring, alerting, and SLO management
- Incident response and postmortem creation

## Repository Structure

```
claudekit/
├── .claude-plugin/
│   ├── plugin.json        # Plugin metadata and configuration
│   └── marketplace.json   # Marketplace listing configuration
├── commands/
│   ├── k8s/              # Kubernetes operations (3 commands)
│   │   ├── deploy.md              # Guided K8s deployment workflow
│   │   ├── troubleshoot.md        # Systematic pod/service debugging
│   │   └── manifest-validate.md   # YAML validation & best practices
│   ├── terraform/        # Infrastructure as Code (3 commands)
│   │   ├── plan-review.md         # Terraform plan analysis
│   │   ├── apply.md               # Safe terraform apply workflow
│   │   └── cloud-cost.md          # Multi-cloud cost optimization
│   ├── cicd/             # CI/CD workflows (2 commands)
│   │   ├── pipeline-new.md        # Create production CI/CD pipeline
│   │   └── deploy-strategy.md    # Blue/green, canary, rolling deploys
│   ├── observability/    # Monitoring & SLOs (2 commands)
│   │   ├── alert-new.md           # Create monitoring alerts
│   │   └── slo-define.md          # Define SLOs/SLIs & error budgets
│   └── incident/         # Incident management (1 command)
│       └── postmortem.md          # Structured postmortem creation
├── CLAUDE.md            # This file - plugin architecture guide
├── README.md            # User-facing documentation
└── LICENSE              # MIT License
```

## Plugin Architecture

### Plugin Configuration

**`.claude-plugin/plugin.json`**: Core plugin metadata including:
- Plugin name, description, version, and author
- Tags for discovery (devops, sre, kubernetes, terraform, etc.)
- License information

**`.claude-plugin/marketplace.json`**: Marketplace configuration for distribution

### Command Organization

Commands are organized by DevOps workflow domain for intuitive discovery:

| Category | Focus Area | Command Count |
|----------|-----------|---------------|
| `k8s/` | Kubernetes operations & troubleshooting | 3 |
| `terraform/` | Infrastructure as Code management | 3 |
| `cicd/` | Pipeline creation, deployment automation, ship pipeline, PR review | 4 |
| `observability/` | Monitoring, alerting, SLOs | 2 |
| `incident/` | Incident response & postmortems | 1 |
| `hooks/` | Claude Code lifecycle hooks and MCP server configuration | 2 |

### Command Structure

Each command follows a consistent, production-ready structure:

1. **YAML Frontmatter**: Metadata with concise description
2. **Requirements Section**: User inputs and prerequisites
3. **Structured Workflow**: Step-by-step guidance with best practices
4. **Multi-Cloud Support**: Examples for AWS, GCP, and Azure where applicable
5. **Safety Checks**: Validation, rollback procedures, and risk mitigation
6. **Output Templates**: Structured formats for deliverables
7. **Best Practices**: Security, reliability, and operational excellence guidelines

**Example Command Pattern**:
```markdown
---
description: Brief, actionable description (< 80 chars)
---

# Command Title

Requirements section defining inputs, prerequisites...

Workflow sections with:
- Clear numbered steps
- Multi-cloud code examples
- Safety validations
- Rollback procedures

Output format templates...

Best practices and operational guidance...
```

## Command Usage

Commands are invoked using the pattern: `/claudekit:<category>:<command>`

**Examples**:
- `/claudekit:k8s:deploy` - Guided Kubernetes deployment
- `/claudekit:terraform:plan-review` - Analyze Terraform plan
- `/claudekit:cicd:pipeline-new` - Create CI/CD pipeline
- `/claudekit:cicd:ship` - Full agentic ship pipeline (review → test → commit → push)
- `/claudekit:cicd:pr-review` - DevOps-focused PR review
- `/claudekit:observability:alert-new` - Create monitoring alert
- `/claudekit:incident:postmortem` - Generate postmortem document
- `/claudekit:hooks:setup` - Configure Claude Code lifecycle hooks
- `/claudekit:hooks:mcp-setup` - Wire MCP servers for AWS, K8s, GitHub

## Key Features

### 1. Multi-Cloud Support

All infrastructure commands support AWS, GCP, and Azure with:
- Cloud-specific examples and CLI commands
- Provider-agnostic patterns where possible
- Best practices for each platform
- Cost optimization guidance per cloud

### 2. Production-Ready Focus

Every command emphasizes:
- Security-first approach (RBAC, secrets management, least privilege)
- Comprehensive validation and pre-checks
- Detailed rollback and recovery procedures
- Error handling and troubleshooting guidance
- Monitoring and observability integration

### 3. SRE Best Practices

Commands incorporate Site Reliability Engineering principles:
- SLO-based alerting and monitoring
- Error budget management
- Blameless postmortem templates
- Chaos engineering considerations
- Incident response frameworks

### 4. Guided Workflows

Each command provides:
- Step-by-step procedures
- Decision trees for complex scenarios
- Checklists for validation
- Reference commands and scripts
- Links to runbooks and documentation

### 5. Agentic Pipelines

Commands like `cicd/ship` and `cicd/pr-review` are full agentic workflows — Claude executes real commands, checks output at each step, aborts on failure, and waits for human confirmation before irreversible actions. This is different from Claude writing scripts for you to run manually.

### 6. Hooks & Guardrails

The `hooks/` category provides lifecycle automation that runs independently of specific commands:
- **PreToolUse hooks**: Block dangerous commands before Claude can run them (`exit 2` = hard block with message)
- **Stop hooks**: Auto-lint and format every file Claude touches after each turn
- These apply globally across all claudekit commands once configured

### 7. Recursive CLAUDE.md

Claude Code reads `CLAUDE.md` recursively. You can place a `CLAUDE.md` inside any subdirectory (e.g. `terraform/modules/vpc/CLAUDE.md`) with directory-specific rules, and Claude will read it automatically when working in that scope. This enables layered context without polluting the root file.

## Development Workflow

### Adding New Commands

1. **Identify DevOps Domain**: Determine appropriate category (k8s, terraform, cicd, etc.)
2. **Create Command File**: Add `.md` file in relevant `commands/<category>/` directory
3. **Follow Structure**:
   ```markdown
   ---
   description: Clear, concise description
   ---

   # Command Title

   ## Requirements
   [User inputs, prerequisites]

   ## Workflow
   [Structured steps with examples]

   ## Output Format
   [Template for deliverables]

   ## Best Practices
   [Security, reliability guidance]
   ```
4. **Multi-Cloud Coverage**: Include examples for AWS/GCP/Azure where applicable
5. **Safety First**: Always include validation, rollback, and error handling
6. **Test Command**: Verify command works in Claude Code with sample inputs

### Extending Categories

To add a new command category:
1. Create new directory under `commands/` (e.g., `commands/networking/`)
2. Add category-specific commands following existing patterns
3. Update this CLAUDE.md documentation
4. Update README.md with new commands

## Command Design Principles

1. **Actionable**: Commands guide users through complete workflows, not just information
2. **Safe**: Include pre-checks, validation, and rollback procedures
3. **Comprehensive**: Cover common scenarios and edge cases
4. **Educational**: Explain why, not just what (best practices context)
5. **Consistent**: Follow established structure and formatting patterns
6. **Multi-Cloud**: Support major cloud providers where relevant
7. **Production-Ready**: Assume production use, emphasize reliability and security
8. **Professional Output**: NEVER include AI attribution signatures such as:
   - "🤖 Generated with [Claude Code]"
   - "Co-Authored-By: Claude <noreply@anthropic.com>"
   - Any AI tool attribution or signature
   - Create clean, professional output without AI references

## Git Workflow

**Branch Strategy:**

- **CRITICAL**: ALWAYS commit to feature branches, NEVER directly to `main`
- Direct commits to `main` are blocked by branch protection workflows
- Use descriptive branch names: `feature/<description>`, `fix/<issue>`, `docs/<topic>`
- Create pull requests for review before merging to main
- Only PR merges and automated release commits are allowed on `main`

**Commit Message Format:**

Follow conventional commit format without AI attributions:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:** feat, fix, docs, style, refactor, test, chore

**Examples:**

```
feat(k8s): add deployment validation command

Add comprehensive Kubernetes deployment workflow with pre-checks,
security validation, and multi-cloud support.
```

```
fix(terraform): correct cost calculation for GCP resources

Update pricing data for Compute Engine instances.
```

```
docs: update README with installation instructions
```

**Rules:**

- No AI attribution signatures in commits
- Use conventional commit format
- Keep commits atomic and focused
- Write clear, descriptive commit messages

## Release Process

Releases are **fully automated** using [semantic-release](https://semantic-release.gitbook.io/semantic-release/).

**How it works:**

1. When a PR is merged to `main`, semantic-release analyzes commits
2. Determines version bump based on conventional commit types:
   - `feat:` → **minor** version bump (1.0.0 → 1.1.0)
   - `fix:` → **patch** version bump (1.0.0 → 1.0.1)
   - `BREAKING CHANGE:` → **major** version bump (1.0.0 → 2.0.0)
   - `docs:`, `chore:`, `refactor:` → no release
3. Automatically:
   - Generates CHANGELOG.md
   - Updates version in `.claude-plugin/plugin.json`
   - Creates git tag
   - Creates GitHub release with notes
   - Commits changes back to `main`

**Configuration:**

- `.releaserc.json` - Semantic-release configuration
- `.github/workflows/release.yaml` - GitHub Actions workflow
- `.github/update-plugin-version.js` - Updates plugin.json version

**No manual steps required** - just use conventional commits and merge to `main` via PR.

## Technical Standards

### Security
- Never hardcode secrets or credentials
- Use cloud provider secret management (Secrets Manager, Key Vault, etc.)
- Enforce least privilege (RBAC, IAM policies)
- Scan for vulnerabilities (container images, dependencies)
- Network security (firewall rules, network policies)

### Reliability
- Health checks (liveness, readiness probes)
- Resource limits and requests defined
- High availability configurations (replicas, PDBs)
- Rollback procedures documented
- Monitoring and alerting configured

### Observability
- Structured logging (JSON format)
- Metrics in Prometheus format
- Distributed tracing support
- SLO-based alerting
- Dashboard links in alerts

### Infrastructure as Code
- Version control all configurations
- Use modules for reusability
- Tag all resources appropriately
- Remote state with locking
- Plan before every apply

## Plugin Metadata

- **Name**: claudekit
- **Version**: 1.0.0
- **Author**: ops4life
- **License**: MIT
- **Tags**: devops, sre, platform-engineering, kubernetes, terraform, cicd, observability, aws, gcp, azure

## Resources

- **Repository**: https://github.com/ops4life/claudekit
- **License**: MIT License (see LICENSE file)
- **Documentation**: README.md for user-facing guide
- **Reference Implementation**: https://github.com/edmund-io/edmunds-claude-code
