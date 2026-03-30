# Spec: PROJ-T-010 -- Sequential IDs work across all commands

## Summary
The counters.json file is the single source of truth for sequential ID generation
across all AEGIS commands (breakdown, kanban add, compliance, ADR). However,
install.sh does not create this file, while install-remote.sh does. This means
local installations start without a counter file, relying on each command to
create it on first use -- which risks race conditions or inconsistent initialization.

## Root Cause
install.sh missing counters.json initialization (install-remote.sh has it at line 228).

## Acceptance Criteria
1. install.sh creates _aegis-brain/counters.json with all counter keys at 0
2. On --upgrade, existing counters.json is preserved (never reset user counters)
3. The format matches what pm-state-protocol.md specifies
4. All counter keys present: US, J, E, T, ST, DOC, ADR, TD, REL, HO

## Havoc Finding Reference
H-023: Task ID conflict breakdown vs kanban (MEDIUM)
