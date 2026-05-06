# Sprint v10-07 Plan: Hermes L2 — Pattern Miner over decision-audit.log

**Status**: SCOPED, NOT YET OPEN — awaiting explicit "open v10-07" go from user.
**Points**: 8pt (planned · subject to revision when sprint opens)
**Goal**: Deterministic pattern miner over `.aegis/brain/logs/decision-audit.log` that surfaces high-confidence repeat-decision patterns as **instinct candidates**, without invoking an LLM. Hermes-adapted: read-only observation, no autonomous skill generation.

## Why now (2026-05-06)

When the v10-08 (L3) deferred-with-rationale was set during sprint-v10-06 (2026-05-02), the gate was: "needs L2 measurement first." The L2 gate in turn was: "needs decision-log data to mine."

That data now exists:

```
$ wc -l .aegis/brain/logs/decision-audit.log
     120

$ jq -r '.source' .aegis/brain/logs/decision-audit.log | sort | uniq -c | sort -rn
  55 judgment           ← pattern-mining target (where instinct could replace fallback)
  17 adr:sprint-v9-02
  12 adr:sprint-v9-04
  11 framework
  10 adr:sprint-v9-03
   9 adr:ADR-001
   3 instinct:promoted
   3 adr:sprint-v9-05
```

**55 judgment-fallback decisions across 11 sprints** is well above the noise threshold for cluster mining. Patterns that recur ≥3 times across sprints are high-confidence candidates for promotion to `instincts/`. v10-07 builds the deterministic miner; v10-08 (L3) closes the loop by feeding promoted instincts back into the decision flow.

## Strategic context (Hermes L2 = AEGIS deterministic miner)

| Layer | Hermes | AEGIS adoption |
|-------|--------|----------------|
| L1 — Retrieval | FTS5 + LLM summarization | **FTS5 only** (sprint-v10-06, DONE 2026-05-02) |
| L2 — Pattern miner | LLM observes prompts | **Deterministic miner** over decision-audit.log (THIS SPRINT) |
| L3 — Refinement loop | LLM rewrites skills | **Instinct refinement** (v10-08, blocked on L2 measurement) |

See `~/.claude/.../memory/project_hermes_adoption_pattern.md` for full rationale on why we reject LLM-generated layers (ISO 29110 audit trail preservation).

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | `aegis-pattern-mine.sh` — read decision-audit.log, output JSON pattern report | 3 | NEW |
| B | Pattern shape definition + stable cluster keys (deterministic, byte-equal across runs) | 2 | NEW |
| C | `aegis-instinct-propose.sh` — write a top-N pattern as instinct candidate (status=`pending`) under `.aegis/brain/instincts/_proposed/<id>.yaml` | 2 | NEW |
| D | Tests + integration with v10-09 instinct-promote flow | 1 | NEW |

### Story A — Pattern miner (3pt)

**Inputs:**
- `.aegis/brain/logs/decision-audit.log` (120+ entries, JSONL)
- `.aegis/brain/instincts/*.yaml` (active instincts, for "this question already has an instinct" filtering)

**Pipeline:**
1. Stream-read the JSONL, focus on `source: judgment` entries (55 today)
2. Cluster by question shape — strip variables (paths, IDs, dates) using a deterministic normalizer (e.g. lowercase + replace `/[\w\-./]+\.(md|sh|mjs|js|yaml|json)/` with `<file>`, replace `[0-9]+` with `<n>`)
3. For each cluster ≥3 occurrences across ≥2 sprints: record the cluster key, member decision_ids, the modal answer, and average confidence
4. Filter out clusters whose normalized question already maps to a promoted instinct (re-mine prevention)
5. Emit `.aegis/brain/state/pattern-mine-report.json` (atomic via temp+rename)

**Output schema (per cluster):**
```jsonc
{
  "cluster_id": "<sha256(normalized_question)[:12]>",
  "normalized_question": "should we ship <n>pt sprint or split?",
  "occurrences": 4,
  "decision_ids": ["D-042", "D-061", "D-080", "D-088"],
  "sprints_seen": ["v9-04", "v10-01", "v10-06", "v12-04"],
  "modal_answer": "ship as one — split adds rebase pain",
  "avg_confidence": 0.91,
  "first_seen_ts": "2026-04-23T...",
  "last_seen_ts": "2026-05-06T...",
  "candidate_instinct_score": 0.86  // weighted: occurrences * avg_confidence * sprint_diversity
}
```

### Story B — Cluster key stability (2pt)

The hardest part. The mine must be **idempotent** — same input produces byte-equal output across runs (cf. v12-04 NDJSON sort discipline). Key levers:

- Normalizer rules versioned in `tools/aegis-pattern-mine/normalizer-rules.yaml` so any change forces a deliberate version bump
- Cluster IDs are content-addressable (SHA256 of normalized question, truncated)
- Output sorted by `(occurrences DESC, cluster_id ASC)` — stable across reordering
- Test: re-run mine on identical input → `cmp -s` returns 0

### Story C — Instinct candidate writer (2pt)

For the top-N clusters (configurable, default N=3), write a YAML file under `.aegis/brain/instincts/_proposed/<cluster_id>.yaml`:

```yaml
status: pending
proposed_at: 2026-XX-XX
source: aegis-pattern-mine
trigger_pattern: "should we ship <n>pt sprint or split?"
recommendation: "ship as one — split adds rebase pain"
confidence: 0.86
evidence:
  - decision_id: D-042
    sprint: v9-04
    ts: 2026-04-23T...
  - ... (up to 5 evidence rows)
```

Existing `aegis-instinct-promote.sh` already handles the `_proposed/<id>.yaml → <id>.yaml` promotion gate (sprint-v10-09); we just feed the queue.

### Story D — Tests + integration (1pt)

- `tests/aegis-pattern-mine-test.sh` — fixture decision-audit.log with 6 known clusters → exact pattern-mine-report.json output
- Determinism test: re-run on same input → byte-equal
- Idempotency test: re-running with `_proposed/<id>.yaml` already present → no overwrite (nor duplicate)
- Filter test: cluster matching a promoted instinct is skipped

## Storage layout (additions only)

```
.aegis/brain/
├── instincts/
│   └── _proposed/                  # 🆕 v10-07 — pattern-mine candidates awaiting human/Captain promotion
│       └── <cluster_id>.yaml
└── state/
    └── pattern-mine-report.json    # 🆕 v10-07 — last full mine output (gitignored, regeneratable)

tools/aegis-pattern-mine/           # 🆕 v10-07 (mine.sh + normalizer-rules.yaml + propose.sh)
```

## Acceptance criteria

- [ ] `tools/aegis-pattern-mine/mine.sh` exists, exits 0 on the live decision-audit.log
- [ ] Output `.aegis/brain/state/pattern-mine-report.json` has ≥1 cluster with occurrences ≥3 (achievable today: 55 judgment entries cluster easily)
- [ ] Two consecutive `mine.sh` runs are byte-equal (`cmp -s` returns 0)
- [ ] `tools/aegis-pattern-mine/propose.sh` writes top-3 to `instincts/_proposed/`
- [ ] Existing promoted instincts are filtered out (no duplicate proposals)
- [ ] Tests: ≥10 assertions covering miner correctness, determinism, filter, propose idempotency
- [ ] `aegis-instinct-promote.sh` accepts a `_proposed/<id>.yaml` and promotes cleanly
- [ ] Roadmap row v10-07: PLANNED → CLOSED 8/8

## Out of scope (this sprint)

- LLM-driven pattern detection (v10-07 is deterministic only, by design)
- Auto-promotion of instincts without human review (would violate ISO 29110 audit trail)
- Cross-project pattern mining (out of scope; v11-09 multi-tenant could surface this later)
- Refinement loop (that's L3 = v10-08, blocked on L2 measurement)

## Open questions for sprint-open

1. Q: Normalizer rule scope — start with 3 rules (paths, numbers, IDs) and expand, or design a richer NLP-y normalizer up front? Recommend: start small.
2. Q: Top-N default — 3? 5? 10? Affects how many candidates land in `_proposed/` per mine.
3. Q: Mine cadence — manual-run only, or wire into PostToolUse / SessionStart? Recommend: manual via `/aegis-mine` for v10-07; automate in v10-08 if proven valuable.
4. Q: Cross-pollination with v11-02 activity-logger — should pattern-mine also read JSONL activity? Probably no (different signal: decisions vs. tool-calls), but worth a 1-line ADR.

## References

- `~/.claude/.../memory/project_hermes_adoption_pattern.md` — Hermes L1/L2/L3 adaptation rationale
- `.aegis/brain/sprints/sprint-v10-06/plan.md` + close.md — L1 (FTS5) baseline, this sprint's predecessor
- `tools/aegis-instinct-promote.sh` — existing instinct promotion flow (v10-09)
- `tools/aegis-log-decision.sh` — the source emitter (S2-02 / v9-02)
- `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` v1.1 — terminal-only / file-as-contract principles inherited

## Why this is SCOPED, not OPEN

Sprint open requires:
1. ✅ Data sufficiency (120 entries, 55 judgment) — MET 2026-05-06
2. ⏳ User explicit "open v10-07" go — NOT YET
3. ⏳ Estimate confidence after open question (1) is decided — defer until kickoff

When ready: user types something like "open v10-07" or "ship pattern miner" → kickoff this plan.
