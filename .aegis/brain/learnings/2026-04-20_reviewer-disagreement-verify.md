---
date: 2026-04-20
category: workflow
confidence: high
---
# Reviewer Disagreement Requires Evidence-Based Adjudication

## Context

Spawned Black Panther (correctness/security review) and Loki (adversarial review) in parallel to gate a commit. Both returned findings on the same files. They agreed on most but contradicted each other on two items:

1. **Black Panther** claimed `v9-session-start-hook.sh:30` pointed to a nonexistent path (`aegis-version-check.sh` in `tools/` not `.claude/hooks/`) and marked it a BLOCKER.
2. **Loki** claimed the same path was correct because `.claude/hooks/aegis-version-check.sh` already exists (confirmed via filesystem).

Main agent had to stop, run `ls -la .claude/hooks/`, and verify. Loki was right. Black Panther's mental model of "where the script lives" was out of date.

Similarly they split on whether to commit `.claude/settings.json.v8-backup`:
- BP said don't (weak security config in git history).
- Loki said yes (rollback safety net needed during v9 transition).

Compromise: gitignore it (keeps local, no history bloat).

## Lesson

Parallel reviewers don't see each other's findings, so disagreements surface silently as contradictory BLOCKER/OK verdicts. The main agent is the only one that sees both reports and must reconcile.

**Never pick one reviewer and discard the other.** Each claim — especially BLOCKER claims — must be independently verified with evidence (filesystem read, bash output, reading the file at the line claimed). An assertion like "X lives at path Y" is a testable claim; test it.

When reviewers compromise on a policy decision (commit vs gitignore vs delete), look for an option that satisfies both concerns rather than picking a side.

## Application

- After spawning `/aegis-team-review` (or any parallel review) and receiving findings, **before** acting:
  1. List every finding from every reviewer.
  2. For each BLOCKER or WARNING, verify the underlying claim with a direct observation (`ls`, `grep`, `cat`, file read).
  3. Where reviewers conflict, resolve with the observation, not reviewer authority.
  4. Where reviewers prescribe opposing actions, look for a "both-are-right" solution (gitignore in the backup-file example).
- Add to review-team orchestration: require reviewers to cite `file:line` or exact bash output for each finding. Unsupported assertions are flagged as low-confidence.
- Consider a tie-breaker protocol: if N-of-M reviewers disagree on a BLOCKER, spawn a 3rd specialist (Beast for facts, Iron Man for architecture) for the decisive vote.
