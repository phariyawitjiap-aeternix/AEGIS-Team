# Retrospective: Sprint v10-01 — Project-Wide Traceability Wiki

> Date: 2026-04-24
> Sprint: v10-01 (13pt, single session)
> Facilitator: Nick Fury

## What Went Well

1. **Single-session delivery**: All 5 stories (13pt) built, tested, dogfood-validated,
   committed, PR'd, and merged in one session. No multi-session handoff overhead.

2. **Dogfood validation worked**: The trace-audit tool (Story E) successfully validated
   its own sprint's deliverables. Found and fixed 2 ghost references in SI.02 during
   the process -- proving the tool catches real issues.

3. **TSV-to-JSON approach**: After the initial pure-bash JSON builder failed on special
   characters, switching to TSV intermediate + Python JSON conversion was the right call.
   Clean separation of scan (bash) from serialization (python3).

4. **Hash-based FUNC IDs**: Using md5 hash of source_file:name produces stable IDs across
   runs without needing a counter file. Idempotency test passes on first try after the
   6-char hash fix.

5. **TI-01 closed**: A debt item open for 1 month (since v7.2 planning) is now shipped.
   The trace audit tool goes beyond what TI-01 originally envisioned (5 checks, not just
   "verify matrix against files").

## What Could Be Improved

1. **Initial FUNC catalog approach too fragile**: The first implementation used bash printf
   for JSON emission. Failed on special characters in agent capability names (parentheses,
   slashes). Lesson: for any JSON generation with untrusted input, use a real serializer.

2. **4-char hash collisions**: Started with 4 hex chars for FUNC IDs, hit a collision
   immediately (aegis-dashboard vs aegis-evolve). Extended to 6 chars. Should have started
   with 6+ from the beginning. 4 hex chars = 65536 values, collision probability non-trivial
   at 400+ entries.

3. **SI.02 ghost references from partial filenames**: The initial audit check extracted
   backtick-enclosed `.md` filenames including bare names like `loki.md` (not paths).
   Fixed by requiring paths to contain `/`. Lesson: be precise about what constitutes
   a "file reference" vs a "filename mention".

## Action Items

- [ ] Consider adding FUNC catalog drift check to CI/pre-commit hook
- [ ] SI.01 requirements spec is still v7.1 vintage -- needs a v9.0 refresh (separate sprint)
- [ ] SI.04 test cases document is stale (still references TC-01..TC-17 from v7.1)

## Metrics

| Metric | Value |
|--------|-------|
| Points delivered | 13/13 (100%) |
| PR merged | #62 |
| Files changed | 15 |
| Lines added | 4761 |
| Lines removed | 111 |
| Tests added | 10 (6 func-catalog + 4 trace-audit) |
| Bugs caught by dogfood | 2 (SI.02 ghost references) |
| TI debt closed | 1 (TI-01) |
