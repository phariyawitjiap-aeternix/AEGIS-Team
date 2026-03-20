---
name: super-spec
description: "Research-driven spec engine: BRD + SRS + UX Blueprint from minimal input"
profile: standard
triggers:
  en: ["write spec", "create spec", "BRD", "SRS", "requirements", "specification"]
  th: ["เขียน spec", "ข้อกำหนด", "เขียนข้อกำหนด", "สร้าง spec"]
---

## Quick Reference
Generates complete project specifications from minimal input.
- **BRD**: Business Requirements Document — stakeholder goals, scope, success criteria
- **SRS**: Software Requirements Specification — functional/non-functional requirements
- **UX Blueprint**: User flows, wireframe descriptions, interaction patterns
- **Pipeline**: Brief → Research → BRD → SRS → UX Blueprint
- **Output**: `_aegis-output/specs/` (BRD.md, SRS.md, UX-Blueprint.md)
- **Agent**: Sage (opus) — primary author

## Full Instructions

### Invocation

```
/super-spec [brd|srs|ux|all] "<project brief>"
```
- `brd` — Generate BRD only
- `srs` — Generate SRS (requires BRD)
- `ux` — Generate UX Blueprint (requires BRD)
- `all` — Full pipeline: BRD → SRS → UX Blueprint (default)

### Phase 1: Research & Clarification

Before generating any spec, gather context:

1. **Parse brief** — Extract key nouns, verbs, constraints
2. **Identify gaps** — What information is missing?
3. **Ask clarifying questions** (max 5):
   - Target users/audience
   - Core problem being solved
   - Key constraints (time, budget, tech)
   - Integration requirements
   - Success metrics
4. **Research** — Analyze similar systems, common patterns

### Phase 2: BRD (Business Requirements Document)

```markdown
# Business Requirements Document
**Project**: <name>
**Version**: 1.0
**Date**: YYYY-MM-DD
**Author**: Sage (AEGIS)

## 1. Executive Summary
<2-3 paragraphs: what, why, for whom>

## 2. Business Objectives
- <objective 1 — measurable>
- <objective 2 — measurable>
- <objective 3 — measurable>

## 3. Stakeholders
| Role | Needs | Priority |
|------|-------|----------|
| <role> | <needs> | High/Medium/Low |

## 4. Scope
### In Scope
- <feature/capability>

### Out of Scope
- <explicitly excluded>

## 5. Success Criteria
| Metric | Target | Measurement |
|--------|--------|-------------|
| <metric> | <target value> | <how measured> |

## 6. Assumptions & Constraints
### Assumptions
- <assumption>

### Constraints
- <constraint>

## 7. Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| <risk> | High/Med/Low | High/Med/Low | <strategy> |

## 8. Timeline
| Phase | Duration | Deliverables |
|-------|----------|-------------|
| <phase> | <weeks> | <deliverables> |
```

### Phase 3: SRS (Software Requirements Specification)

```markdown
# Software Requirements Specification
**Project**: <name>
**Version**: 1.0
**Date**: YYYY-MM-DD
**Based on**: BRD v1.0

## 1. System Overview
<Architecture overview, tech stack recommendations>

## 2. Functional Requirements

### FR-001: <Feature Name>
- **Description**: <what the system shall do>
- **Input**: <expected input>
- **Processing**: <business logic>
- **Output**: <expected output>
- **Priority**: Must Have / Should Have / Nice to Have
- **Acceptance Criteria**:
  - GIVEN <context> WHEN <action> THEN <result>

### FR-002: ...

## 3. Non-Functional Requirements

### Performance
- NFR-P01: Response time < <X>ms for 95th percentile
- NFR-P02: Support <N> concurrent users

### Security
- NFR-S01: Authentication via <method>
- NFR-S02: Data encryption at rest and in transit

### Scalability
- NFR-SC01: Horizontal scaling to <N> instances

### Reliability
- NFR-R01: 99.9% uptime SLA
- NFR-R02: Recovery time < <X> minutes

### Maintainability
- NFR-M01: Test coverage > 80%
- NFR-M02: Documentation for all public APIs

## 4. Data Models
### Entity: <Name>
| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| <field> | <type> | <constraints> | <description> |

## 5. API Specifications
### <METHOD> <endpoint>
- **Purpose**: <description>
- **Auth**: Required/Public
- **Request**: <schema>
- **Response**: <schema>
- **Errors**: <error codes>

## 6. Integration Points
| System | Protocol | Purpose |
|--------|----------|---------|
| <system> | REST/gRPC/MQ | <purpose> |

## 7. Dependency Matrix
| Requirement | Depends On | Blocked By |
|-------------|-----------|------------|
| <FR-XXX> | <FR-YYY> | <none/FR-ZZZ> |
```

### Phase 4: UX Blueprint

```markdown
# UX Blueprint
**Project**: <name>
**Version**: 1.0
**Date**: YYYY-MM-DD
**Based on**: BRD v1.0, SRS v1.0

## 1. User Personas
### Persona: <Name>
- **Role**: <role>
- **Goals**: <what they want to achieve>
- **Pain Points**: <current frustrations>
- **Tech Proficiency**: Low/Medium/High

## 2. User Flows

### Flow: <Name>
```
[Start] → [Step 1] → [Decision?]
                        ├─ Yes → [Step 2a] → [End]
                        └─ No  → [Step 2b] → [Step 3] → [End]
```

## 3. Screen Inventory
| Screen | Purpose | Key Components | Navigation |
|--------|---------|---------------|------------|
| <screen> | <purpose> | <components> | <from/to> |

## 4. Wireframe Descriptions
### Screen: <Name>
- **Layout**: <grid/flex description>
- **Header**: <contents>
- **Main content**: <components and arrangement>
- **Actions**: <buttons, forms>
- **States**: <loading, empty, error, success>

## 5. Interaction Patterns
| Pattern | Usage | Behavior |
|---------|-------|----------|
| <pattern> | <where used> | <how it works> |

## 6. Responsive Strategy
- **Mobile** (< 768px): <approach>
- **Tablet** (768-1024px): <approach>
- **Desktop** (> 1024px): <approach>

## 7. Accessibility
- WCAG 2.1 AA compliance targets
- Keyboard navigation for all interactive elements
- Screen reader support with ARIA labels
- Color contrast ratios ≥ 4.5:1
```

### Output Location

All specs are saved to:
```
_aegis-output/specs/
  BRD.md
  SRS.md
  UX-Blueprint.md
```

### Quality Gate

Before marking specs complete:
- [ ] All sections filled (no TODOs or placeholders)
- [ ] Requirements are testable (clear acceptance criteria)
- [ ] No contradictions between BRD, SRS, and UX Blueprint
- [ ] Scope is realistic for stated constraints
- [ ] Review by Vigil for completeness (if team mode)
