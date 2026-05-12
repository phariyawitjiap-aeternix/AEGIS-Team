---
date: 2026-05-08
category: tooling
confidence: high
---
# `git --merged` misses squash-merged branches → combine with PR state

## Context

During session-end branch cleanup, classified 19 orphan branches via `git branch -r --merged origin/main` and `git branch -r --no-merged origin/main`:
- 9 reported as merged
- 10 reported as NOT merged (looked risky to delete)

Almost stopped there. Spot-checked the 10 "not merged" branches via `gh pr list --state all --head <branch>` and found **all 10 had MERGED PRs** — they were squash-merged, which produces a NEW commit SHA on main. Git's `--merged` is commit-lineage-based, so squash-merge breaks the lineage check entirely.

Net effect: `git --merged` falsely reported 10 branches as risky-to-delete when they were 100% safe.

## Lesson

`git branch --merged` only detects branches whose commits are reachable from main via parent-chain traversal. **Squash-merge produces a new commit SHA** — the original branch's HEAD is no longer in main's lineage, so `--merged` returns false negative.

GitHub's PR state (`mergedAt` field on the PR record) is the **authoritative source of truth** for "did this branch's work ship to main." Combine both signals for accurate classification.

## Application

For any branch-cleanup workflow:

```bash
# Step 1: Lineage-merged (reliable for non-squash flows)
git branch -r --merged origin/main

# Step 2: PR-state check (catches squash-merged)
for branch in $(git branch -r --no-merged origin/main | sed 's|^[ *]*origin/||'); do
  state=$(gh pr list --state all --head "$branch" --json state,mergedAt --jq '.[0] | "\(.state)|\(.mergedAt // "n/a")"')
  echo "$branch: $state"
done
```

A branch is **safe to delete** if EITHER:
- `git --merged` reports it as merged (lineage-merge), OR
- `gh pr list` reports a PR with `state: MERGED` and non-null `mergedAt` (squash-merge)

Repos that default to squash-merge (most modern GitHub orgs) will produce mostly false negatives from `--merged` alone. Tool worth building: `tools/aegis-branch-cleanup.sh` that fuses both signals and only proposes deletion of verified-merged branches.
