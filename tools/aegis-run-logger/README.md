# aegis-run-logger

Archives each session's transcript to `.aegis/brain/runs/<YYYY-MM-DD>-<session>/`
(gitignored, local-only) and lets you list / replay / garbage-collect them.

| Script | Purpose |
|--------|---------|
| `archive.mjs` | Stop-hook: copies the session transcript + writes `meta.json`. Append-only. |
| `list.mjs` | Summarize archived runs (`--since`, `--persona`, `--limit`, `--json`). |
| `replay.mjs` | Replay an archived run. |
| `gc.mjs` | **Retention / garbage-collection.** Prunes old run dirs. |

## Garbage collection (`gc.mjs`)

`archive.mjs` never prunes, so `runs/` grows without bound (it reached 114 MB /
38 runs before the first GC — see `docs/p5-brain-inventory.md`). Run `gc.mjs`
periodically to reclaim disk.

**Retention policy** — a run is **kept** if EITHER holds (conservative):
- it is among the newest `--keep N` runs (by run-id date), OR
- it is newer than `--days D` days.

Everything else is pruned. **Dry-run by default** — nothing is deleted unless
you pass `--apply`.

```bash
# Preview what would be removed (safe, default keep=10 days=30)
node tools/aegis-run-logger/gc.mjs

# More aggressive preview
node tools/aegis-run-logger/gc.mjs --keep 5 --days 14

# Actually delete
node tools/aegis-run-logger/gc.mjs --apply

# Machine-readable report
node tools/aegis-run-logger/gc.mjs --json
```

Flags: `--keep N` (default 10), `--days D` (default 30), `--apply` (default
dry-run), `--json`.

Safety: `gc.mjs` only ever removes **direct child directories of
`.aegis/brain/runs/`** — it never touches any other brain subdir. Each target's
parent is verified to resolve to `runs/` before deletion.

### Optional: schedule it

It is a manual command by design (the Stop hook stays lean and fail-open). To
automate, add a cron entry or a scheduled task, e.g. weekly:

```cron
0 3 * * 1  cd /path/to/repo && node tools/aegis-run-logger/gc.mjs --apply >/dev/null 2>&1
```
