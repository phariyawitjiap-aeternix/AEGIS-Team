# Sprint v11-08 Plan: aegis-trace-export (PII redaction)

**Points**: 8pt · **Branch**: `feat/v11-08-aegis-trace-export`
**Final v11 Phase-2 sprint** — completes the AEGIS-Plus Mega Plan v1.1 in-repo scope.

## Goal

Export traces from `.aegis/brain/activity/*.jsonl` with PII/secret redaction. Closes G8.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | redaction/patterns.yaml — defaults from Mega Plan §15 B | 1 |
| B | export.mjs CLI — read activity range, redact, write JSONL | 4 |
| C | validate.mjs — scan exported file, fail if any pattern matches | 1 |
| D | SKILL.md + tests | 2 |

## Storage

- `.aegis/brain/redaction/patterns.yaml` — `[ {label, regex, replacement?} ]`
- `.aegis/brain/exports/<YYYY-MM-DD>-<topic>.jsonl` — redacted output, one record per line

## Acceptance criteria (Mega Plan §7.4)

- [ ] Zero matches against patterns in exported file (validated by validate.mjs)
- [ ] Pattern file supports username, email, common API-key formats, home paths
- [ ] CLI: `--since <Nd|YYYY-MM-DD> --topic <name> [--out file]`
- [ ] Replacement text configurable per pattern (default `[REDACTED-{label}]`)
- [ ] Exit non-zero if validate fails
