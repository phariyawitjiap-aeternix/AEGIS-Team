# Sprint v15-14 — install-remote.sh manifest drift fix (issue #182)

> Fix the bug class where `install-remote.sh` ships partial files —
> agents + top-level scripts but NOT hook libs and NOT multi-file tool
> packages. Result: 11 orphan references that `aegis-doctor` flags but
> the installer dismisses with a single `[WARN]` and exits 0.

## Sprint metadata

- **ID**: sprint-v15-14-install-manifest-fix
- **Points**: 5
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-14-install-manifest-fix`
- **Driver**: [Issue #182](https://github.com/phariyawitjiap-aeternix/AEGIS-Team/issues/182) — filed via Correction Register CR-001 from Contra-Thai install

## Root cause

`install-remote.sh` had two manifest gaps:

1. **No copy of `.claude/hooks/lib/`** — `on-stop.sh` sources 4 modules
   (`quality-check`, `mbp-scan`, `false-ready`, `queue-banner`) that
   were never shipped. The `safe_source` defensive code (v15-12) keeps
   the hook from crashing but the doctor reports them as orphans.

2. **Tool packages not copied** — only `tools/aegis-*.sh` (single
   files) were copied via glob. Multi-file directories like
   `aegis-approval-gate/`, `aegis-live-tail/`, `aegis-brain-graph/`,
   `aegis-activity-logger/`, `aegis-run-logger/`, `aegis-resume/`,
   `aegis-multi-tenant/`, `_hook-utils/` (15+ packages) were silently
   skipped. settings.json references their `.mjs` entry points → 11
   orphans on doctor.

Compounding: post-install doctor was **warn-only**. The installer
exited 0 even when 11 references didn't resolve.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — Ship `.claude/hooks/lib/` | 1 | Recursive copy + chmod after main hooks. Required by `on-stop.sh`. |
| B — Glob-discover tool packages | 2 | Replace hand-coded list with `for pkg_dir in tools/*/`. Future packages auto-ship. `_archived` skipped. `*.yaml` (threat-patterns config) also shipped. |
| C — Make doctor fail-loud | 1 | Post-install doctor exit non-zero → installer exits 1 with diagnostic. Removes the `[WARN]` masking. |
| D — Regression test | 1 | `tests/aegis-install-manifest-test.sh` × 4 scenarios: install completes / doctor PASS / 13 critical files shipped / doctor exits non-zero on injected orphan. |

## Acceptance criteria

1. `bash install-remote.sh --profile full` on fresh dir → `aegis-doctor` exits 0 (was exit 1 with 11 orphans).
2. `.claude/hooks/lib/` directory shipped with 4 modules.
3. 15+ multi-file tool packages shipped (`aegis-approval-gate/`, `aegis-live-tail/`, `_hook-utils/`, etc.).
4. Doctor found-orphans → installer exits 1 with actionable recovery message.
5. Regression test added to CI; 4/4 PASS.
6. Full suite 59/59 (was 58, +1).

## Out of scope

- **Self-heal fetch from raw.githubusercontent.com** (proposal #3 in issue) — would let `aegis-doctor --fix` work without a sibling checkout. Larger change; deferred to v15-15 candidate.
- **Migrating install.sh's hand-coded `tool_packages` list** to glob discovery too — the local installer works for current users; not blocking. Sync as separate cleanup.

## Verification plan

1. `bash tests/aegis-install-manifest-test.sh` → 4/4 PASS
2. `bash tests/run-all.sh --continue` → 59/59 PASS
3. Smoke install in fresh `mktemp -d` → doctor reports clean
4. Close issue #182 on merge
