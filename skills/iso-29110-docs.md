# Skill: iso-29110-docs
> Profile: full
> Triggers EN: ISO, 29110, compliance, audit docs, work products
> Triggers TH: ไอเอสโอ, เอกสารมาตรฐาน, ตรวจสอบ

## Purpose
Generate and maintain ISO/IEC 29110 Basic profile compliant work products from AEGIS agent outputs. Covers both Project Management (PM) and Software Implementation (SI) processes.

## When to Use
- After sprint planning to generate/update Project Plan (PM.01)
- After daily standups or sprint reviews to update Progress Status (PM.02)
- When scope changes to log Change Requests (PM.03)
- After any sprint ceremony to record Meeting Minutes (PM.04)
- After work breakdown to generate Requirements Specification (SI.01)
- After architecture design to generate Design Document (SI.02)
- After any document update to refresh Traceability Matrix (SI.03)
- After QA planning to generate Test Plan (SI.04)
- After QA execution to generate Test Report (SI.05)
- After QA gate pass to generate Acceptance Record (SI.06)
- At release time to generate Software Configuration (SI.07)
- When auditing compliance gaps via /aegis-compliance check

---

## Quick Reference

```
/aegis-compliance generate    -- Generate all missing ISO docs from current state
/aegis-compliance check       -- Audit which docs are missing or outdated
/aegis-compliance matrix      -- Show/update traceability matrix
```

---

## ISO 29110 Basic Profile -- Full Document Catalog

### Project Management (PM) Process

#### PM.01 -- Project Plan
- **Content**: Task descriptions, effort estimates, schedule, milestones, resource assignments, risk identification, version control strategy
- **Source data**: Sprint plan (_aegis-brain/sprints/), backlog (_aegis-brain/backlog.md), kanban assignments, Havoc risk analysis
- **Auto-trigger**: Generated at sprint planning, updated each sprint
- **Location**: _aegis-output/iso-docs/project-plan.md

#### PM.02 -- Progress Status Record
- **Content**: Actual vs planned progress, identified problems, deviations, corrective actions
- **Source data**: Kanban board state, burndown data, agent StatusUpdate messages, blocker tracking
- **Auto-trigger**: Updated at daily standups and sprint reviews
- **Location**: _aegis-output/iso-docs/progress-status.md

#### PM.03 -- Change Request Log
- **Content**: Requested changes, impact analysis, approval status, implementation status
- **Source data**: Scope changes tracked by Navi, EscalationAlert messages
- **Auto-trigger**: When scope changes are detected or requested
- **Location**: _aegis-output/iso-docs/change-requests.md

#### PM.04 -- Meeting Records
- **Content**: Date, attendees (agents), agenda, decisions, action items
- **Source data**: Sprint ceremony outputs (planning, standup, review, retro)
- **Auto-trigger**: After each sprint ceremony completes
- **Location**: _aegis-output/iso-docs/meeting-minutes/YYYY-MM-DD-<type>.md

### Software Implementation (SI) Process

#### SI.01 -- Requirements Specification
- **Content**: Functional requirements, non-functional requirements, constraints, acceptance criteria
- **Source data**: Work breakdown outputs from Sage (/aegis-breakdown)
- **Auto-trigger**: When /aegis-breakdown completes
- **Location**: _aegis-output/iso-docs/requirements-spec.md

#### SI.02 -- Software Design Document
- **Content**: Architecture overview, component design, interfaces, data model, design decisions
- **Source data**: Sage architecture specs, ADRs (docs/decisions/)
- **Auto-trigger**: When Sage completes architecture spec
- **Location**: _aegis-output/iso-docs/design-doc.md

#### SI.03 -- Traceability Record
- **Content**: Matrix linking Requirement -> Design section -> Code file -> Test case -> Test result
- **Source data**: Cross-reference of all above documents + Bolt commit refs + Probe test results
- **Auto-trigger**: Updated whenever any linked document changes
- **Location**: _aegis-output/iso-docs/traceability-matrix.md
- **Computation**: Scribe auto-generates by scanning requirements IDs, design section anchors, code references from commits, test case IDs, and test results

#### SI.04 -- Test Plan
- **Content**: Test strategy, test cases, test data, pass/fail criteria, environment requirements
- **Source data**: Sentinel test plan (_aegis-output/qa/)
- **Auto-trigger**: When /aegis-qa plan completes
- **Location**: _aegis-output/iso-docs/test-plan.md

#### SI.05 -- Test Report
- **Content**: Test execution summary, pass/fail counts, defects found, QA verdict
- **Source data**: Probe execution results + Sentinel verdict (_aegis-output/qa/)
- **Auto-trigger**: When /aegis-qa run completes
- **Location**: _aegis-output/iso-docs/test-report.md

#### SI.06 -- Acceptance Record
- **Content**: Acceptance criteria checklist, QA verdict reference, sign-off record
- **Source data**: QA gate pass + human sign-off (via Navi)
- **Auto-trigger**: When QA gate passes and human approves
- **Location**: _aegis-output/iso-docs/acceptance-record.md

#### SI.07 -- Software Configuration
- **Content**: Release version, included components, build instructions, deployment notes, known issues
- **Source data**: Release artifacts from Bolt, git tags, CHANGELOG
- **Auto-trigger**: At release preparation
- **Location**: _aegis-output/iso-docs/release/release-<version>.md

---

## Document Lifecycle

Every ISO 29110 document follows this lifecycle:

| Stage | Action | Responsible |
|-------|--------|-------------|
| **Draft** | Generated by Scribe from source data | Scribe |
| **Review** | Checked for completeness and consistency | Vigil |
| **Approved** | Formal approval (or escalation to human) | Navi |
| **Baselined** | Version-tagged in git via commit | Navi + git |

Status is tracked in a header block at the top of each document:
```markdown
---
document_id: PM.01
title: Project Plan
version: 1.2
status: Approved
last_updated: 2026-03-24
author: scribe
reviewer: vigil
approver: navi
---
```

---

## Traceability Matrix Format

```markdown
# Traceability Matrix

| Req ID | Requirement | Design Ref | Code Ref | Test Case | Test Result | Status |
|--------|------------|------------|----------|-----------|-------------|--------|
| REQ-001 | <text> | design-doc#section-2 | src/auth.ts | TC-001 | PASS | Verified |
| REQ-002 | <text> | design-doc#section-3 | src/api.ts | TC-002 | FAIL | Open |
```

**Computation method**: Scribe scans and cross-references:
1. Requirement IDs from _aegis-output/breakdown/ and iso-docs/requirements-spec.md
2. Design section anchors from iso-docs/design-doc.md
3. Code file references from Bolt implementation commits
4. Test case IDs from _aegis-output/qa/ test plans
5. Test results from _aegis-output/qa/results/

---

## Workflow

1. Scribe receives TaskAssignment (from Navi or triggered by pipeline event)
2. Scribe reads source data from _aegis-output/ and _aegis-brain/
3. Scribe generates or updates the target ISO document
4. Scribe stamps document with version, date, and status=Draft
5. If traceability matrix is affected, Scribe regenerates it
6. Scribe sends StatusUpdate to Navi confirming document generation
7. Vigil reviews document for completeness (Gate 3: Compliance)
8. Navi approves or escalates to human

## Inputs
- Agent outputs in _aegis-output/ (specs, reviews, QA results, breakdowns)
- Sprint data in _aegis-brain/sprints/
- Backlog in _aegis-brain/backlog.md

## Outputs
- ISO 29110 documents in _aegis-output/iso-docs/
- Traceability matrix in _aegis-output/iso-docs/traceability-matrix.md

## Agent Routing
- **Primary**: Scribe (document generation)
- **Assist**: Muse (for prose-heavy sections like executive summaries)
- **Review**: Vigil (document completeness check)
- **Approval**: Navi (formal sign-off)

## Examples
```
# Generate all missing ISO docs
/aegis-compliance generate

# Check compliance gaps
/aegis-compliance check
> Missing: PM.02 (Progress Status), SI.05 (Test Report)
> Outdated: PM.01 (Project Plan -- last updated 3 sprints ago)

# Update traceability matrix
/aegis-compliance matrix
> Traceability matrix updated: 12 requirements, 10 traced, 2 gaps found
> Gap: REQ-007 has no test case
> Gap: REQ-011 has no design reference
```
