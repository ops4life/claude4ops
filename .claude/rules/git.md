# Git

## Pushing

Always stage and commit first, then fetch+rebase, then push:

```bash
git add <files> && git commit -m "..." && git fetch origin && git rebase origin/main && git push
```

`git rebase` fails with unstaged changes. Never rebase before committing.

If SSH push fails (for example `Permission denied (publickey)`), switch `origin`
to HTTPS and retry:

```bash
git remote set-url origin https://github.com/<owner>/<repo>.git
git fetch origin
git rebase origin/main
git push origin main
```

## Commit messages

No `Co-Authored-By` or any AI attribution lines in commit messages.
