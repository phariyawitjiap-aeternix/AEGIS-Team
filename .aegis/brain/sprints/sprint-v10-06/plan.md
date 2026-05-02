# Sprint v10-06 Plan: Searchable Brain (Hermes L1)

**Sprint Goal**: Add FTS5 full-text search over `.aegis/brain/` so agents can recall handoffs, retros, learnings, resonance, sprints, and decision logs by topic — not just by knowing the filename.
**Points**: 5pt total (2+3)
**Duration**: 1 session (2026-05-02)

## Strategic Context

First of three sprints (v10-06/07/08) adopting Nous Research Hermes Agent's compounding-intelligence pattern. AEGIS adapts the **observed** layers (FTS5 retrieval, pattern miner, refinement loop) and explicitly rejects the LLM-generated layers (autonomous skill creation) to preserve ISO 29110 audit trail.

| Layer | Hermes | AEGIS adoption |
|-------|--------|----------------|
| L1 — Retrieval | FTS5 + LLM summarization | **FTS5 only** (this sprint, v10-06) |
| L2 — Pattern miner | LLM observes prompts | **Deterministic miner** over decision-audit.log (v10-07, deferred) |
| L3 — Refinement loop | LLM rewrites skills | **Instinct refinement** based on observed-vs-actual outcomes (v10-08, deferred) |

See `~/.claude/.../memory/project_hermes_adoption_pattern.md` for full rationale.

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | `aegis-brain-index.sh` — FTS5 indexer over brain dirs + logs | 2 | NEW |
| B | `aegis-brain-search.sh` — query interface (type/since/json/limit filters) | 3 | NEW |

### Story A — Brain indexer (2pt) ✅

- **Schema**: `entries(id, source_type, source_path, line_no, ts, content_summary, mtime)` + FTS5 virtual table on `content_summary, source_type, source_path`
- **Sources indexed**: `handoffs/`, `retros/`, `learnings/`, `resonance/`, `sprints/` (paragraph blocks for `.md`); `logs/activity.log`, `logs/decision-audit.log` (line-by-line)
- **Modes**: `--full` (rebuild + backup), `--incremental` (mtime check), `--stats`
- **Tokenizer**: `porter unicode61` for stemmed English search
- **Triggers**: `entries_ai/ad/au` keep FTS in sync with base table
- **Acceptance**: 91 files / 4,388 entries / 3.0 MB DB after first full build (verified 2026-05-02)

### Story B — Brain search (3pt) ✅

- **Filters**: `--type {handoffs|retros|learnings|resonance|sprints|decisions|other}`, `--since YYYY-MM-DD`, `--limit N`
- **Output**: ranked text (default, with bm25 + snippet highlights) or `--json` (one JSON-object per line, ready for `jq`)
- **Provenance**: every result includes `source_path:line_no` so user can `:line` into the file
- **Acceptance**: query "MBP violation" returns 10 ranked decision-log hits; `--type learnings` filter returns only learnings; `--since` filter respects mtime; no-match query exits 0 with clean message

## Out of scope (deferred)

- LLM summarization of indexed content (Hermes L1 second half) — would require external LLM call per index, breaks deterministic indexing
- Auto-incremental indexing on file save (hook integration) — defer until search adoption is proven
- Hot-key brain search from `/aegis-status` or other commands — UX integration, not core capability
- `.aegis/brain/conversations/` indexing — high-volume, low-signal; reconsider after 1 month of L1 usage
- Vector embeddings — out of scope per Hermes-adoption decision (defer to v10-09+ if FTS5 proves insufficient)

## Dependencies

- `sqlite3` CLI (already required by AEGIS for other tooling)
- No external LLM, no network, no new Python/Node dependencies
- Pure bash + sqlite3 → fits AEGIS deterministic philosophy

## Success Criteria

- [x] FTS5 index builds cleanly from a fresh `.aegis/brain/` (idempotent)
- [x] Search returns ranked, provenance-tagged results in <1s for 4k entries
- [x] All filter combinations work (type, since, limit, json)
- [x] No-match case is graceful (exit 0, helpful message)
- [x] Tools documented in CLAUDE.md observability table
- [x] Sprint added to `roadmap.md` for grand-total tracking
