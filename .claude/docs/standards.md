# Technical Standards

## Security
- Never hardcode secrets or credentials
- Use cloud provider secret management (Secrets Manager, Key Vault, etc.)
- Enforce least privilege (RBAC, IAM policies)
- Scan for vulnerabilities (container images, dependencies)
- Network security (firewall rules, network policies)

## Reliability
- Health checks (liveness, readiness probes)
- Resource limits and requests defined
- High availability configurations (replicas, PDBs)
- Rollback procedures documented
- Monitoring and alerting configured

## Observability
- Structured logging (JSON format)
- Metrics in Prometheus format
- Distributed tracing support
- SLO-based alerting
- Dashboard links in alerts

## Infrastructure as Code
- Version control all configurations
- Use modules for reusability
- Tag all resources appropriately
- Remote state with locking
- Plan before every apply

# Release Process

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
