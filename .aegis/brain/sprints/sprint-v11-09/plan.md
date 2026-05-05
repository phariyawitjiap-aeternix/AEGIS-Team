# Sprint v11-09 Plan: aegis-multi-tenant

**Points**: 5pt · **Branch**: `feat/v11-09-aegis-multi-tenant`
**Phase-3 trigger met**: 3+ active AEGIS projects on this machine (AEGIS-Team / kam-tong-ham / RizzLab).

## Goal

Folder convention + helpers for managing multiple AEGIS projects with cross-project visibility. Closes Mega Plan §8.2.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `~/.aegis-plus/projects.yaml` registry — register / list / where helpers | 2 |
| B | Cross-project aggregator — `node mt.mjs activity --since 7d --all-projects` | 2 |
| C | SKILL.md + tests | 1 |

## Storage

- `~/.aegis-plus/projects.yaml` — single registry across user's machine
  ```yaml
  projects:
    - name: AEGIS-Team
      path: /Users/.../Documents/AEGIS-Team
      role: meta
    - name: kam-tong-ham
      path: /Users/.../Documents/kam-tong-ham
      role: pilot
    - name: RizzLab
      path: /Users/.../Documents/RizzLab
      role: production
  ```

## Acceptance criteria

- [ ] `mt.mjs register` adds a project (or refuses duplicate)
- [ ] `mt.mjs list` shows all registered projects + their AEGIS_VERSION + role
- [ ] `mt.mjs where <name>` prints the absolute path of one project
- [ ] `mt.mjs activity --all-projects --since Nd` aggregates JSONL across projects
- [ ] `mt.mjs issues --all-projects` lists open issues across projects
- [ ] All commands gracefully handle a registered path that no longer exists

## Out of scope

- aegis-resume (Phase-3 §8.1) — trigger not met (no crash-loss incidents observed)
- Project-cloning helpers
- Shared persona/instinct sync across projects
