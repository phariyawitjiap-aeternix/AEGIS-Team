---
date: 2026-04-22
category: tooling
confidence: high
---
# Merging --delete-branch on a Base Branch Auto-Closes Stacked PRs

## Context

Opened 4 PRs for MBP enforcement fixes:
- PR #20 (MBP core) based on `main`
- PR #22 (false-ready) based on #20's branch `fix/master-brain-protocol-enforcement`
- PR #23 (command-chain) based on #20's branch

Ran `gh pr merge 20 --merge --delete-branch`. This deleted the base branch that #22 and #23 were stacked on → GitHub auto-CLOSED both PRs as `CONFLICTING` (base missing).

Attempted `gh pr edit 22 --base main` to retarget → **failed** with "Cannot change the base branch of a closed pull request".
Attempted `gh pr reopen 22` → **failed** with "Could not open the pull request" (because base still didn't exist).

Had to create fresh PRs (#24, #25) from the same branches with `--base main`. Wasted review history attached to the closed PRs.

## Lesson

Before merging a PR that has stacked children, **retarget the children first**:

```bash
# Before merging the parent:
gh pr edit <child-pr-1> --base main
gh pr edit <child-pr-2> --base main
# Then merge parent:
gh pr merge <parent> --merge --delete-branch
# Children are now main-based and can merge cleanly
```

Or: merge the parent *without* `--delete-branch`, merge children, then delete the parent branch afterward.

## Application

- **Stacked PRs are a pattern, not a one-off.** When you open child PRs with `--base <parent-branch>`, track them and retarget before parent merge.
- **GitHub's closed-PR restrictions are asymmetric**: you can retarget an *open* PR freely, but once closed you lose that edit permission. Order matters.
- **Preventative habit**: before running `gh pr merge --delete-branch` on any branch, run `gh pr list --base <branch>` to surface children.
- **Recovery is possible but costly**: fresh PRs lose review history, comments, and CI status. If reviews matter, prefer restoring the base branch (`git push origin <sha>:refs/heads/<branch>`) then reopen → retarget → merge; don't just create new PRs.
