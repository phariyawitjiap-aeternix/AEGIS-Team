# Sprint v15-14 Close — install-remote.sh manifest fix (closes #182)

**Status**: CLOSED (100%)
**Date**: 2026-05-18
**Tests**: 59/59 (added `aegis-install-manifest-test.sh` × 4 scenarios)
**Closes**: [#182](https://github.com/phariyawitjiap-aeternix/AEGIS-Team/issues/182)
**Branch**: `claude/sprint-v15-14-install-manifest-fix`

## What shipped

1. **`.claude/hooks/lib/` copy** — 4 modules that `on-stop.sh` sources now ship with every install.

2. **Tool packages glob-discovery** — replaces hand-coded list. `for pkg_dir in tools/*/` ships every directory under `tools/` (except `_archived`). Future packages auto-ship without editing the installer:

   ```bash
   for pkg_dir in "${TMP_DIR}/tools/"*/; do
       pkg_name=$(basename "$pkg_dir")
       case "$pkg_name" in
           _archived) continue ;;
       esac
       mkdir -p "${TARGET_DIR}/tools/${pkg_name}"
       cp -R "${pkg_dir}." "${TARGET_DIR}/tools/${pkg_name}/" 2>/dev/null || true
       find "${TARGET_DIR}/tools/${pkg_name}" -type f \( -name "*.sh" -o -name "*.mjs" \) -exec chmod +x {} + 2>/dev/null || true
   done
   ```

3. **`.yaml` config files** in `tools/` (e.g. `aegis-brain-threat-patterns.yaml`) also ship.

4. **Doctor fail-loud** — if `aegis-doctor.sh` finds orphans, installer exits 1 with the orphan list + recovery hint instead of swallowing the warning:

   ```
   [ERROR] Doctor found orphan references — install is INCOMPLETE.
     · .claude/hooks/on-stop.sh → .claude/hooks/lib/quality-check.sh
     · settings.json → tools/aegis-approval-gate/check.mjs
     · …

   [ERROR] Recovery:
     bash <target>/tools/aegis-doctor.sh <target> --fix
     (requires a sibling AEGIS-Team checkout under $HOME)
   ```

5. **Regression test** — `tests/aegis-install-manifest-test.sh`:
   - T1 install completes (exit 0)
   - T2 doctor on fresh install (exit 0)
   - T3 13 critical files shipped (incl. hooks/lib, _hook-utils, all 5 wired .mjs entry points)
   - T4 doctor exits non-zero when an orphan is injected (validates fail-loud path)

## Issue #182 verification

```
$ bash install-remote.sh --profile full --project-name "Repro" --no-linear --no-mt
# … all install steps …
[OK] Doctor: all references resolve ✓        ← was: [WARN] Doctor found orphans
=== AEGIS v15.0 — Installation Complete! ===
```

`bash tools/aegis-doctor.sh` on the fresh install → exit 0, zero orphans. Before this sprint, doctor reported 11.

## Behavior change visible to users

| Scenario | Before | After |
|---|---|---|
| Fresh install with full manifest | exit 0 + `[WARN]` + 11 orphans | exit 0 + `✓ all references resolve` |
| Install with broken manifest | exit 0 + `[WARN]` (silent) | exit 1 + orphan list + recovery hint |
| Adding a new tool package | Required editing installer's hand-list | Auto-shipped (glob discovery) |

## Out of scope (deferred to v15-15+)

- **`aegis-doctor --fix` raw.githubusercontent.com fallback** (issue #182 proposal #3). Currently `--fix` only works with a sibling `AEGIS-Team` checkout under `$HOME`. Users installing into a single project without prior AEGIS history can't auto-recover. Larger change.
- **Migrating `install.sh`'s hand-coded `tool_packages` list to glob** — local installer still uses the old pattern. Works for current contributors but has the same drift risk.

## Roadmap impact

v15 net: 37pt → 42pt.
