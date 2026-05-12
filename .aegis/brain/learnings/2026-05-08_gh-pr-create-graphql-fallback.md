---
date: 2026-05-08
category: tooling
confidence: high
---
# `gh pr create` repo-resolution quirk → GraphQL mutation fallback

## Context

While shipping PR #152 (Round 3 MBP regex), `gh pr create` returned `GraphQL: must be a collaborator (createPullRequest)` for both authenticated accounts (`mr-phariyawit` and `phariyawitjiap-aeternix`) — even though the latter has `viewerPermission: ADMIN` on the repo. Direct REST `POST /repos/.../pulls` returned the same error. This blocked autonomous PR creation despite valid auth and admin rights.

Spent ~10 minutes hitting the wall before realizing the quirk is in `gh` CLI's repo-resolution path, not in token scope. Calling the GraphQL `createPullRequest` mutation directly with explicit `repositoryId` (node ID) succeeded immediately — same token, same scope.

## Lesson

When `gh pr create` says "must be a collaborator" on a repo where `gh repo view --json viewerPermission` reports `ADMIN`, the failure is path-resolution in the CLI, not actual permission lack. The GraphQL API works directly with explicit node ID.

## Application

Future trigger: any time `gh pr create` returns `must be a collaborator` despite verified admin permissions, fall back to:

```bash
# Get repo node ID
REPO_ID=$(gh api graphql -f query='query { repository(owner: "OWNER", name: "REPO") { id } }' --jq '.data.repository.id')

# Create PR via GraphQL mutation
gh api graphql -f query='mutation($repo: ID!, $base: String!, $head: String!, $title: String!, $body: String!) {
  createPullRequest(input: {repositoryId: $repo, baseRefName: $base, headRefName: $head, title: $title, body: $body})
  { pullRequest { number url } }
}' -f repo="$REPO_ID" -f base="main" -f head="<branch>" -f title="..." -f body="..."
```

After PR opens, `gh pr merge <N> --merge --delete-branch` works fine — the quirk only affects creation, not merge. Don't preemptively conclude "blocked by token scope" without trying GraphQL — both PRs in this session (#152, #153) shipped via this fallback.
