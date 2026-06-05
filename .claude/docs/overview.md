# Project Overview

**claude4ops** is a comprehensive Claude Code plugin that brings DevOps superpowers to everyone. It provides production-ready slash commands to streamline and automate complex workflows across infrastructure management, deployment, observability, and incident response.

**Purpose**: Enhance DevOps productivity with guided workflows, best practices, and automated procedures for:
- Kubernetes operations and troubleshooting
- Infrastructure as Code (Terraform) management
- CI/CD pipeline creation and deployment strategies
- Monitoring, alerting, and SLO management
- Incident response and postmortem creation

## Repository Structure

```
claude4ops/
├── .claude-plugin/
│   ├── plugin.json        # Plugin metadata and configuration
│   └── marketplace.json   # Marketplace listing configuration
├── .claude/
│   ├── rules/
│   │   └── git.md             # Git workflow rules
│   └── docs/
│       ├── overview.md        # This file
│       ├── architecture.md    # Plugin architecture and commands
│       ├── development.md     # Dev workflow and design principles
│       └── standards.md       # Technical standards and release process
├── commands/
│   ├── install.md        # Install claude4ops hooks, skills, rules, and settings
│   ├── update.md         # Resync scripts from plugin source after updates
│   ├── k8s/              # Kubernetes operations (3 commands)
│   │   ├── deploy.md              # Guided K8s deployment workflow
│   │   ├── troubleshoot.md        # Systematic pod/service debugging
│   │   └── manifest-validate.md   # YAML validation & best practices
│   ├── terraform/        # Infrastructure as Code (3 commands)
│   │   ├── plan-review.md         # Terraform plan analysis
│   │   ├── apply.md               # Safe terraform apply workflow
│   │   └── cloud-cost.md          # Multi-cloud cost optimization
│   ├── cicd/             # CI/CD workflows (4 commands)
│   │   ├── pipeline-new.md        # Create production CI/CD pipeline
│   │   ├── deploy-strategy.md     # Blue/green, canary, rolling deploys
│   │   ├── ship.md                # Full agentic ship pipeline
│   │   └── pr-review.md           # DevOps-focused PR review
│   ├── observability/    # Monitoring & SLOs (2 commands)
│   │   ├── alert-new.md           # Create monitoring alerts
│   │   └── slo-define.md          # Define SLOs/SLIs & error budgets
│   ├── incident/         # Incident management (1 command)
│   │   └── postmortem.md          # Structured postmortem creation
│   └── hooks/            # Hooks and MCP configuration (2 commands)
├── rules/                # Global rules installed to ~/.claude/rules/
│   └── git.md
├── setup.sh              # Interactive setup script (settings, hooks, MCP, skills, rules, plugin)
├── settings.json         # Base Claude Code settings template
├── skills/               # Claude Code skills installed to ~/.claude/skills/ by setup.sh
│   └── docling/
│       └── SKILL.md          # Convert PDF/DOCX/images to Markdown before implementation
├── scripts/              # Scripts installed to ~/.claude/ by setup.sh
│   ├── statusline-command.sh  # Rate limit + model status bar
│   └── hooks/
│       ├── block-prod.sh      # PreToolUse: block prod commands
│       ├── auto-lint.sh       # Stop: lint/format on every turn
│       ├── audit-bash.sh      # PostToolUse: audit log
│       └── slack-notify.sh    # Notification: Slack alerts
├── CLAUDE.md             # Root index - imports all docs via @
├── README.md             # User-facing documentation
└── LICENSE               # MIT License
```

## Plugin Metadata

- **Name**: claude4ops
- **Version**: 1.2.0
- **Author**: ops4life
- **License**: MIT
- **Tags**: devops, sre, platform-engineering, kubernetes, terraform, cicd, observability, aws, gcp, azure

## Resources

- **Repository**: https://github.com/ops4life/claude4ops
- **License**: MIT License (see LICENSE file)
- **Documentation**: README.md for user-facing guide
- **Reference Implementation**: https://github.com/edmund-io/edmunds-claude-code
