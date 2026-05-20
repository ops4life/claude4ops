# Plugin Architecture

## Plugin Configuration

**`.claude-plugin/plugin.json`**: Core plugin metadata including:
- Plugin name, description, version, and author
- Tags for discovery (devops, sre, kubernetes, terraform, etc.)
- License information

**`.claude-plugin/marketplace.json`**: Marketplace configuration for distribution

## Command Organization

Commands are organized by DevOps workflow domain for intuitive discovery:

| Category | Focus Area | Command Count |
|----------|-----------|---------------|
| `k8s/` | Kubernetes operations & troubleshooting | 3 |
| `terraform/` | Infrastructure as Code management | 3 |
| `cicd/` | Pipeline creation, deployment automation, ship pipeline, PR review | 4 |
| `observability/` | Monitoring, alerting, SLOs | 2 |
| `incident/` | Incident response & postmortems | 1 |
| `hooks/` | Claude Code lifecycle hooks and MCP server configuration | 2 |

## Command Structure

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

### Multi-Cloud Support

All infrastructure commands support AWS, GCP, and Azure with:
- Cloud-specific examples and CLI commands
- Provider-agnostic patterns where possible
- Best practices for each platform
- Cost optimization guidance per cloud

### Production-Ready Focus

Every command emphasizes:
- Security-first approach (RBAC, secrets management, least privilege)
- Comprehensive validation and pre-checks
- Detailed rollback and recovery procedures
- Error handling and troubleshooting guidance
- Monitoring and observability integration

### SRE Best Practices

Commands incorporate Site Reliability Engineering principles:
- SLO-based alerting and monitoring
- Error budget management
- Blameless postmortem templates
- Chaos engineering considerations
- Incident response frameworks

### Guided Workflows

Each command provides:
- Step-by-step procedures
- Decision trees for complex scenarios
- Checklists for validation
- Reference commands and scripts
- Links to runbooks and documentation

### Agentic Pipelines

Commands like `cicd/ship` and `cicd/pr-review` are full agentic workflows — Claude executes real commands, checks output at each step, aborts on failure, and waits for human confirmation before irreversible actions. This is different from Claude writing scripts for you to run manually.

### Hooks & Guardrails

The `hooks/` category provides lifecycle automation that runs independently of specific commands:
- **PreToolUse hooks**: Block dangerous commands before Claude can run them (`exit 2` = hard block with message)
- **Stop hooks**: Auto-lint and format every file Claude touches after each turn
- These apply globally across all claudekit commands once configured

### Recursive CLAUDE.md

Claude Code reads `CLAUDE.md` recursively. You can place a `CLAUDE.md` inside any subdirectory (e.g. `terraform/modules/vpc/CLAUDE.md`) with directory-specific rules, and Claude will read it automatically when working in that scope. This enables layered context without polluting the root file.
