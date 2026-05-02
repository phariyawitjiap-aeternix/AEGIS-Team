# Sprint v10-06 Close: Searchable Brain (Hermes L1)

**Closed**: 2026-05-02
**Delivered**: 5/5 pt (100%)
**Branch**: `feat/v10-06-searchable-brain`

## Stories Delivered

| ID | Story | Pt | Status |
|----|-------|----|----|
| A | `tools/aegis-brain-index.sh` — FTS5 indexer | 2 | ✅ DONE |
| B | `tools/aegis-brain-search.sh` — query interface | 3 | ✅ DONE |

## Verification

- **Index build**: 91 files indexed cleanly into 4,388 FTS5 entries (3.0 MB)
- **Search smoke tests** (all passed):
  - `bash tools/aegis-brain-search.sh "MBP violation"` → 10 ranked hits with snippet highlights
  - `bash tools/aegis-brain-search.sh --type learnings "policy"` → 3 learnings hits, no decision-log noise
  - `bash tools/aegis-brain-search.sh --since 2026-04-25 --type retros "sprint"` → respects mtime + type filters
  - `bash tools/aegis-brain-search.sh --json "hermes" --limit 2` → valid JSON, parseable by `jq`
  - `bash tools/aegis-brain-search.sh "xyzabc999"` → "No matches", exit 0
- **Source-type coverage**: 6/6 source types (handoffs, retros, learnings, resonance, sprints, decisions) all present in index after `--full`

## Bug Fixed Mid-Sprint

- `WHERE_SQL=$(IFS=' AND '; echo "${WHERE_CLAUSES[*]}")` doesn't work in bash — `IFS` only takes single chars. Replaced with explicit string-concat loop. First filter test caught it cleanly.

## Hermes Adoption Status

- **L1 (Searchable Brain)** — ✅ shipped this sprint
- **L2 (Pattern miner)** — deferred to v10-07; will mine `decision-audit.log` for repeated decision shapes and propose instinct candidates
- **L3 (Refinement loop)** — deferred to v10-08; needs L2 measurement first

## Follow-ups (none required)

- No new ADRs needed — pure additive tooling
- No human-queue items — between-session apply not required (no settings.json or hooks touched)
- No CI changes needed — bash + sqlite3 already in environment

## Lessons

1. **bash IFS limitation** — joining array elements with multi-char delimiter requires explicit loop, not `IFS=` trick
2. **FTS5 default tokenizer matters** — `porter unicode61` gave better stem matches than the default for this corpus
3. **Provenance pays for itself** — `source_path:line_no` in every result means user can immediately open the file at the right line; would have lost half the value without it
4. **Deferred is honest** — explicitly listing what's out of scope (LLM summarization, conversation indexing, vector embeddings) prevents scope creep without writing them off forever
