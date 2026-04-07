# Spec: PROJ-T-002 -- install.sh creates ALL directories including tasks/

## Summary
The installer's directory list is incomplete. Several directories that AEGIS
agents expect to exist are missing: tasks/, skill-cache/, metrics/,
learnings/raw/, research/, architecture/archive/. When agents try to write
to these paths, they fail silently or error out.

## Acceptance Criteria
1. install.sh creates _aegis-brain/tasks/ directory
2. install.sh creates _aegis-brain/skill-cache/ directory
3. install.sh creates _aegis-brain/metrics/ directory
4. install.sh creates _aegis-brain/learnings/raw/ directory
5. install.sh creates _aegis-output/research/ directory
6. install.sh creates _aegis-output/architecture/archive/ directory
7. All directories are created via the existing directories array (consistent pattern)

## Havoc Finding Reference
H-002: install.sh missing output directories (CRITICAL)
