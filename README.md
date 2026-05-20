# claudekit — DevOps Superpowers for Everyone

![claudekit banner](./assets/banner.svg)

Production-ready DevOps superpowers for everyone. Streamline and automate complex workflows across AWS, GCP, Azure, and Kubernetes.

## Installation

### Quick Install (Recommended)

```
/plugin marketplace add ops4life/claudekit
/plugin install claudekit
```

### From Local Source

```bash
git clone https://github.com/ops4life/claudekit.git
# In Claude Code:
# /plugin marketplace add /absolute/path/to/claudekit
# /plugin install claudekit
```

### Setup

After installing the plugin, run `/claudekit:install` to configure Claude Code:

- **Scope**: user (`~/.claude/`) or project (`.claude/`)
- **Settings**: `settings.json` merge + status line script
- **Hooks**: block-prod, auto-lint, audit, Slack notifications
- **MCP servers**: AWS, Kubernetes, GitHub
- **Skills**: docling (PDF/DOCX/image → Markdown)
- **Rules**: git workflow standards

Requires [`jq`](https://jqlang.org).

## Commands

All commands: `/claudekit:<category>:<command>`

### Kubernetes

| Command | Description |
|---------|-------------|
| `/claudekit:k8s:deploy` | Guided deployment with pre/post validation and rollback |
| `/claudekit:k8s:troubleshoot` | Systematic debugging for pods, services, and network issues |
| `/claudekit:k8s:manifest-validate` | YAML validation for syntax, security, and best practices |

### Terraform

| Command | Description |
|---------|-------------|
| `/claudekit:terraform:plan-review` | Risk, security, and cost analysis of a Terraform plan |
| `/claudekit:terraform:apply` | Safe apply with state backup and rollback procedures |
| `/claudekit:terraform:cloud-cost` | Multi-cloud cost analysis and right-sizing recommendations |

### CI/CD

| Command | Description |
|---------|-------------|
| `/claudekit:cicd:pipeline-new` | Generate production CI/CD pipeline (GitHub Actions, GitLab, Jenkins) |
| `/claudekit:cicd:ship` | Full agentic pipeline: lint → test → confirm → commit → push |
| `/claudekit:cicd:pr-review` | DevOps-focused review: Terraform, secrets, containers, pipelines |
| `/claudekit:cicd:deploy-strategy` | Design blue/green, canary, or rolling deployment strategy |

### Observability

| Command | Description |
|---------|-------------|
| `/claudekit:observability:slo-define` | Define SLOs/SLIs with error budgets and burn-rate alerting |
| `/claudekit:observability:alert-new` | Create SLO-based monitoring alerts with runbook links |

### Install & Automation

| Command | Description |
|---------|-------------|
| `/claudekit:install` | Install hooks, skills, rules, and settings — user or project scope |
| `/claudekit:hooks:mcp-setup` | Configure MCP servers for AWS, Kubernetes, and GitHub |

### Incident Management

| Command | Description |
|---------|-------------|
| `/claudekit:incident:postmortem` | Blameless postmortem with timeline, RCA, and action items |

## Common Workflows

**Deploy to Kubernetes:**
```
/claudekit:k8s:manifest-validate → /claudekit:k8s:deploy → /claudekit:k8s:troubleshoot
```

**Infrastructure change:**
```
/claudekit:terraform:plan-review → /claudekit:terraform:apply → /claudekit:terraform:cloud-cost
```

**Feature ship:**
```
/claudekit:cicd:pr-review main → work on feature → /claudekit:cicd:ship feat(api): add rate limiting
```

**First-time setup (do once):**
```
/claudekit:install → /claudekit:hooks:mcp-setup
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full guide: setup, command structure, worked example, commit format, and PR process.

## Resources

- [CONTRIBUTING.md](./CONTRIBUTING.md) — contributor guide
- [CLAUDE.md](./CLAUDE.md) — plugin architecture
- [.github/RELEASING.md](./.github/RELEASING.md) — release process
- [Edmund's Claude Code](https://github.com/edmund-io/edmunds-claude-code) — reference implementation

## License

MIT — see [LICENSE](./LICENSE)
