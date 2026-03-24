# /aegis-compliance -- ISO 29110 Compliance Management

> Triggers EN: compliance, ISO, audit, work products, traceability
> Triggers TH: ตรวจสอบ, เอกสาร, ไอเอสโอ, ร่องรอย

## Purpose
Generate, audit, and maintain ISO/IEC 29110 Basic profile work products using the Scribe sub-agent. Ensures all required compliance documents exist, are current, and maintain full traceability from requirements through to test results.

## Subcommands

### /aegis-compliance generate
Generate all missing or outdated ISO 29110 documents from current project state.

**Flow**:
1. Scan _aegis-output/iso-docs/ for existing documents
2. Scan _aegis-output/ and _aegis-brain/ for source data
3. Identify which documents can be generated (source data exists)
4. Spawn Scribe to generate each missing/outdated document
5. Update traceability matrix after all documents generated
6. Report summary: generated, skipped (no source data), already current

### /aegis-compliance check
Audit which ISO 29110 documents are missing, outdated, or incomplete.

**Flow**:
1. Read the full ISO 29110 Basic profile document catalog (PM.01-PM.04, SI.01-SI.07)
2. Check _aegis-output/iso-docs/ for each required document
3. For existing documents, check if source data has changed since last generation
4. Report:
   - Missing documents (required but not generated)
   - Outdated documents (source data newer than document)
   - Current documents (up to date)
   - Compliance score: X/11 documents current

**Output format**:
```
ISO 29110 Compliance Audit
==========================
Current:  7/11 documents up to date
Missing:  2 documents (PM.02, SI.05)
Outdated: 2 documents (PM.01, SI.03)

Details:
  [OK]      PM.01 Project Plan (v1.2, 2026-03-20)
  [MISSING] PM.02 Progress Status Record
  [OK]      PM.03 Change Request Log (v1.0, 2026-03-18)
  [OK]      PM.04 Meeting Records (3 records)
  [OK]      SI.01 Requirements Specification (v2.1, 2026-03-22)
  [OK]      SI.02 Software Design Document (v1.3, 2026-03-21)
  [STALE]   SI.03 Traceability Matrix (last update: 2026-03-19, source changed: 2026-03-22)
  [OK]      SI.04 Test Plan (v1.0, 2026-03-22)
  [MISSING] SI.05 Test Report
  [OK]      SI.06 Acceptance Record (v1.0, 2026-03-23)
  [OK]      SI.07 Software Configuration (v1.0, 2026-03-23)

Action: Run /aegis-compliance generate to fix gaps.
```

### /aegis-compliance matrix
Show or update the traceability matrix that links requirements to design, code, and tests.

**Flow**:
1. Read requirements from _aegis-output/breakdown/ and iso-docs/requirements-spec.md
2. Read design references from iso-docs/design-doc.md
3. Read code references from Bolt implementation records
4. Read test cases from _aegis-output/qa/
5. Read test results from _aegis-output/qa/results/
6. Compute the cross-reference matrix
7. Write to _aegis-output/iso-docs/traceability-matrix.md
8. Report gaps (requirements without tests, code without design refs, etc.)

## Agent Routing
- **Primary**: Scribe (generates all documents)
- **Assist**: Muse (prose-heavy sections if needed)
- **Data source**: All other agents' outputs (Sage, Bolt, Vigil, Sentinel, Probe)

## Output Location
_aegis-output/iso-docs/

## Quality Gate
This command feeds into Gate 3 (Compliance) of the 3-gate quality system:
- Gate 1: Code Quality (Vigil) -- code review, lint, standards
- Gate 2: Product Quality (Sentinel) -- functional tests, acceptance criteria
- Gate 3: Compliance (Scribe) -- all required ISO docs exist and are current

Sprint close is blocked until Gate 3 passes (/aegis-compliance check shows 11/11 current).
