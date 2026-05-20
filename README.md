# claudekit - DevOps/SRE/Platform Engineering Toolkit for Claude Code

Production-ready slash commands for DevOps, SRE, and Platform Engineering workflows across AWS, GCP, and Azure.

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

### Hooks & Automation

| Command | Description |
|---------|-------------|
| `/claudekit:hooks:setup` | Wire auto-lint, prod guard, audit log, and Slack alert hooks |
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

**First-time hooks setup (do once per project):**
```
/claudekit:hooks:setup → /claudekit:hooks:mcp-setup
```

## Setup

Run `setup.sh` to install Claude Code configuration into `~/.claude/`:

```bash
./setup.sh           # interactive menu
./setup.sh --all     # install everything with defaults
./setup.sh --help    # show all flags
```

| Flag | Installs |
|------|---------|
| `--settings` | `settings.json` + `statusline-command.sh` (rate limit status bar) |
| `--hooks` | Hook scripts + wires them in `settings.json` |
| `--mcp` | MCP server config for AWS, Kubernetes, GitHub |
| `--skills` | Skills (docling: PDF/DOCX/image → Markdown) |
| `--plugin` | Registers claudekit plugin in `settings.json` |
| `--all` | All of the above |

**Hooks installed:**
- `block-prod.sh` — blocks kubectl/terraform/aws commands targeting prod
- `auto-lint.sh` — lints every file Claude touches after each turn
- `audit-bash.sh` — appends all Bash commands to `~/.claude/audit.log`
- `slack-notify.sh` — posts Claude alerts to Slack (requires `SLACK_WEBHOOK`)

Requires `jq` (auto-installed via `apt-get` or `brew` if missing).

## Contributing

1. Fork → feature branch → changes in `commands/<category>/`
2. Follow command structure in [CLAUDE.md](./CLAUDE.md)
3. Conventional commit format (`feat:`, `fix:`, `docs:`)
4. PR to `main` — releases are automated via semantic-release

## Resources

- [CLAUDE.md](./CLAUDE.md) — plugin architecture
- [.github/RELEASING.md](./.github/RELEASING.md) — release process
- [Edmund's Claude Code](https://github.com/edmund-io/edmunds-claude-code) — reference implementation

## License

MIT — see [LICENSE](./LICENSE)
