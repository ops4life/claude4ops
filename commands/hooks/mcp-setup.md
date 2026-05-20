---
description: Configure MCP servers for AWS, Kubernetes, and GitHub direct API access
---

# MCP Server Setup - Real Infrastructure API Access

Configure Model Context Protocol (MCP) servers to give Claude direct access to your infrastructure APIs. Instead of Claude writing scripts for you to run, it calls AWS, Kubernetes, and GitHub APIs natively as tools.

## Requirements

**User must provide:**
- Target platforms (AWS, Kubernetes, GitHub, or combination)
- AWS profile name for dev access
- Kubeconfig path for non-prod cluster
- GitHub personal access token (or `GITHUB_TOKEN` env var)

## What MCP Enables

With MCP configured, Claude can:
- "List all S3 buckets without versioning in us-east-1 and enable it on each one"
- "Get all pods in OOMKilled state across every namespace and show memory limits vs actual usage"
- "Find all open PRs older than 7 days with no reviewer assigned and post a reminder comment"

Claude doesn't write you a script. It calls the API, reads the response, and takes the action.

## Setup

### Prerequisites

```bash
# For AWS MCP server
pip install awslabs.aws-mcp-server
# or
uvx awslabs.aws-mcp-server --help  # verify uvx works

# For Kubernetes MCP server
npm install -g mcp-server-kubernetes  # or use npx

# For GitHub MCP server
npm install -g @modelcontextprotocol/server-github  # or use npx
```

### Configure `.claude/settings.json`

Add `mcpServers` to your project `.claude/settings.json`:

```json
{
  "mcpServers": {
    "aws": {
      "command": "uvx",
      "args": ["awslabs.aws-mcp-server"],
      "env": {
        "AWS_PROFILE": "dev",
        "AWS_REGION": "us-east-1"
      }
    },
    "kubernetes": {
      "command": "npx",
      "args": ["mcp-server-kubernetes"],
      "env": {
        "KUBECONFIG": "~/.kube/dev-config"
      }
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Security:** Always use your least-privilege dev profile. Never point `AWS_PROFILE` at production.

## Verification Steps

After configuring, verify each MCP server loads correctly:

1. Start Claude Code — MCP servers initialize on startup
2. Ask Claude: "What MCP tools do you have available?"
3. Test AWS: "List S3 buckets in us-east-1" (read-only, safe to test)
4. Test Kubernetes: "List all namespaces in the cluster"
5. Test GitHub: "List open PRs in this repo"

## Combine With PreToolUse Hooks

MCP gives Claude real API access — pair it with a PreToolUse block-prod hook to prevent Claude from accidentally touching production resources:

```bash
# ~/.claude/hooks/block-prod.sh
# Add MCP-specific patterns alongside Bash patterns:
MCP_DANGER_PATTERNS=(
  '"profile":"production"'
  '"cluster":"prod"'
  '"environment":"prod"'
)
```

See `/claudekit:hooks:setup` for full hook configuration.

## AWS MCP: Common Use Cases

```
# Audit
"List all IAM roles with * in their policies"
"Find EC2 instances not tagged with Environment or Team"
"List RDS instances without encryption enabled"

# Remediation
"Enable versioning on all S3 buckets in us-east-1 that don't have it"
"Add missing tags to all EC2 instances in the dev environment"

# Cost
"List the top 10 EC2 instances by cost this month"
"Find unattached EBS volumes older than 7 days"
```

## Kubernetes MCP: Common Use Cases

```
# Observability
"Get all pods in OOMKilled state and show their memory limits"
"List pods that have restarted more than 5 times in the last hour"
"Show resource usage vs limits for all pods in the payments namespace"

# Operations
"Scale the payments deployment to 3 replicas in dev"
"Get logs from the last crashed pod in the api namespace"
"List all services without a corresponding deployment"
```

## GitHub MCP: Common Use Cases

```
# PR management
"List all open PRs older than 7 days with no reviewer assigned"
"Post a comment on PR #123 with the review checklist"
"Find all PRs touching the terraform/ directory in the last 30 days"

# Repo health
"List open issues labelled 'bug' with no assignee"
"Find all workflows that use actions pinned to a branch instead of SHA"
```

## Best Practices

- Use read-only AWS profiles for exploration, separate write-enabled profile for remediation
- Set `KUBECONFIG` to a dev/staging cluster only — never prod kubeconfig in MCP config
- Rotate `GITHUB_TOKEN` regularly; use a machine account token, not personal
- Commit `.claude/settings.json` to share MCP config with the team (tokens come from env vars, not the file)
- Combine MCP access with `/claudekit:cicd:pr-review` for live state validation during reviews
