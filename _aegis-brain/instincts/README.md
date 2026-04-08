# Instinct System

> Confidence-scored learned patterns with lifecycle promotion.
> Upgrade to the freeform `_aegis-brain/learnings/` lessons file.

## Lifecycle

```
pending  ──(2+ observations, confidence > 0.5)──> active
active   ──(confidence > 0.8)────────────────────> promoted
any      ──(90 days no reinforcement)────────────> retired
```

| Stage | Used by | Weight |
|-------|---------|--------|
| `pending/` | no one (observed but not trusted yet) | 0 |
| `active/` | Loki loads in adversarial reviews | warning |
| `promoted/` | Iron Man loads in every spec + Loki auto-REJECTs violations | hard rule |
| `retired/` | archived, not loaded | 0 |

## Schema

Each instinct is a YAML file with this structure:

```yaml
id: avoid-redis-sessions
status: active              # pending | active | promoted | retired
confidence: 0.72            # 0.0 – 1.0
observations: 3             # how many times this pattern repeated
first_seen: 2026-02-15
last_reinforced: 2026-04-07
cluster: session-storage    # used by /aegis-evolve to group similar instincts
pattern: |
  When storing session data:
  - DON'T: Redis without persistence config (no AOF)
  - DO: Postgres with row-level locks + TTL column
rationale: |
  Observed 3 race conditions when Redis was used without AOF.
  All 3 fixed by migrating to Postgres row-level locks.
```

## Commands

| Command | Purpose |
|---------|---------|
| `/aegis-instinct status` | List all instincts grouped by stage with confidence bars |
| `/aegis-instinct reinforce <id>` | +0.15 confidence, update `last_reinforced`, promote if > threshold |
| `/aegis-instinct retire <id>` | Move to `retired/` |
| `/aegis-instinct export` | Tar `active/` + `promoted/` for sharing |
| `/aegis-instinct import <tarball>` | Import from another project |
| `/aegis-evolve` | Cluster similar instincts, merge duplicates, auto-promote |

## Filename Convention

```
_aegis-brain/instincts/<stage>/<id>.yaml
```

Where `<id>` is the `id` field from the YAML (kebab-case, unique across all stages).

## How Loki uses instincts

Before every adversarial review, Loki loads:
1. All `active/` instincts as **warnings** (flag violations but don't auto-reject)
2. All `promoted/` instincts as **hard rules** (auto-REJECT on violation)

This is how AEGIS's lesson system becomes a self-enforcing immune system.
