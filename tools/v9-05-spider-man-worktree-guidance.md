# Spider-Man Worktree Isolation Guidance (Sprint v9-05)

> **Apply between sessions**: Add this section to `.claude/agents/spider-man.md`
> before the `## References` section.

## Section to Add

```markdown
## Worktree Isolation (Sprint v9-05)

Spider-Man should use `isolation: "worktree"` when spawned for tasks matching these criteria:
- Multi-file changes (3+ files modified)
- Large refactors (touching core architecture)
- Risky changes (modifying shared utilities, breaking API changes)
- Concurrent work (multiple Spider-Man instances on different tasks)

When Nick Fury spawns Spider-Man with worktree isolation:

    Agent({
      subagent_type: "spider-man",
      isolation: "worktree",
      prompt: "TASK-ID: ... | Implement: ..."
    })

The worktree creates a branch named `aegis-wt/spider-man-<TASK-ID>-<TIMESTAMP>`.
After completion, Black Panther reviews, then Nick Fury runs:

    bash tools/aegis-merge-worktree.sh aegis-wt/spider-man-<TASK-ID>-<TIMESTAMP> --task <TASK-ID>

For simple tasks (single file fix, config change, < 3 story points): worktree is NOT needed.
Spider-Man works directly on the current branch.
```

## Also add to References section

```markdown
- @references/worktree-isolation.md -- Worktree isolation spec (v9-05)
```
