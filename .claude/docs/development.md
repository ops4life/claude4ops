# Development Workflow

## Adding New Commands

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

## Extending Categories

To add a new command category:
1. Create new directory under `commands/` (e.g., `commands/networking/`)
2. Add category-specific commands following existing patterns
3. Update `.claude/docs/overview.md` with new structure
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
