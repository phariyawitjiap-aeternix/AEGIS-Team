# AI-3: Branch protection audit + recommendation

**Sprint**: v13-02-cleanup · **Date**: 2026-05-07 · **Owner**: Thor

## Audit finding

`main` branch on `phariyawitjiap-aeternix/AEGIS-Team` has **no branch protection rules configured**:

```
$ gh api repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection
{"message":"Branch not protected","status":"404"}
```

This explains the v13-01 sprint pattern where 7 PRs merged with red CI on at least one matrix axis (mostly macOS-CI flakes + pre-existing env-state-dependent failures).

## What's missing

The current state allows ANY of the following:
- ✅ Merging a PR while `tests/run-all.sh` is failing
- ✅ Force-pushing to main
- ✅ Deleting main
- ✅ Pushing directly to main without a PR
- ✅ Merging without code review
- ✅ Squash-merging without status checks passing

## Recommendation

Configure branch protection rules on `main` with these settings:

### Tier 1 (minimum — safe to enable now)

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "tests/run-all.sh (ubuntu-latest)",
      "tests/run-all.sh (macos-latest)",
      "governance docs (version-headers + changelog)",
      "skill frontmatter schema",
      "knowledge graph builds byte-equal across runs",
      "policy-without-test scanner"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

This blocks merging when CI matrix is red, but doesn't require human review (since the user is solo-maintaining the repo and uses agents for review). `enforce_admins=false` lets the user override in genuine emergencies.

### Tier 2 (stricter — once test suite is reliably green)

Add `required_pull_request_reviews` with at least 0 approvals + dismissal of stale reviews. Useful when a co-maintainer joins.

### Tier 3 (strictest — for production-grade)

- `required_pull_request_reviews.required_approving_review_count: 1`
- `enforce_admins: true`
- Add a "no-bypass" CI check that runs the full `bash tests/run-all.sh` in a clean container

## Implementation

This requires the user to run the gh API call directly (it's an account-settings change, not a code change, so it's classified as **External Access** under MBP — needs by-name go from the user).

Suggested command for Tier 1:

```bash
gh api -X PUT repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "tests/run-all.sh (ubuntu-latest)",
      "tests/run-all.sh (macos-latest)",
      "governance docs (version-headers + changelog)",
      "skill frontmatter schema",
      "knowledge graph builds byte-equal across runs",
      "policy-without-test scanner"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Trade-offs

**Pro**: prevents the "merge red CI" pattern that hid bugs across v13-01 (e.g. install-v11 brain-graph delivery silently broken for ~1 month before sprint-v13-01 caught it).

**Con**: emergency hotfixes get slower. CI flake (e.g. macOS parallel-dispatch transient fail in PR #148 retry) becomes blocking until retry passes.

**Mitigation for con**: the auto-retry pattern (push empty commit) is fast (< 2 min on average). Genuine flake is rare (~1 in 10 CI runs).

## Status

**This file is the recommendation.** The actual gh API call is an External Access action and requires the user to run it. Filed in the human-queue if the user wants to enable it.

## When to revisit

- After 5 PRs land cleanly with full green CI on first try → tighten to Tier 2
- After the test suite gets a "no-flake" review (ideally part of v13-03 or whenever) → consider Tier 3
- If a team member joins → upgrade to Tier 2 for review-required workflow
