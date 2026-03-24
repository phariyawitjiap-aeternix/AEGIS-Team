# DataReport: ISO/IEC 29110 Real-World Implementation Research
**Agent:** Forge (Scanner & Research)
**Date:** 2026-03-24
**Task:** Authoritative research on ISO 29110 — actual standard requirements, not assumptions

---

## FINDING 1: Standard Structure and Applicable Versions

### Active Standards (as of 2026)

| Part | Document | Status | Notes |
|------|----------|--------|-------|
| 1-1 | ISO/IEC 29110-1-1:2024 | Current | Overview |
| 3-2 | ISO/IEC 29110-3-2:2018 | Current | Conformity certification scheme |
| 4-1 | ISO/IEC 29110-4-1:2018 | Current | Profile specifications (normative) |
| 5-1-1 | ISO/IEC 29110-5-1-1:2025 | Current | Entry profile guidelines |
| 5-1-2 | ISO/IEC 29110-5-1-2:2025 | Current | **Basic profile guidelines (FREE)** |
| 5-1-3 | ISO/IEC 29110-5-1-3 | In revision (DIS) | Intermediate profile |
| 5-4 | ISO/IEC 29110-5-4:2025 | NEW | Agile software development guidelines |

**Critical note:** The 2011 version (TR 29110-5-1-2:2011) is the most widely cited in academic literature and Thai certifications. The 2025 update (5-1-2:2025) supersedes it but the process structure is the same. Part 5-1-2 is available **free from ISO/ITTF**.

Sources:
- https://www.iso.org/standard/82669.html (5-1-2:2025)
- https://www.iso.org/standard/67223.html (4-1:2018)
- https://www.iso.org/standard/82668.html (5-4:2025 Agile)

---

## FINDING 2: Profile Hierarchy — Entry vs Basic vs Intermediate

### Generic Profile Group (software engineering)

```
Entry  ──►  Basic  ──►  Intermediate  ──►  Advanced
  |           |                |
 ≤6pm      single app      multi-project
 startup    1 team          parallel teams
```

| Attribute | Entry Profile | Basic Profile |
|-----------|--------------|---------------|
| Target | Startups, projects up to 6 person-months | Single application, one work team |
| Processes | Same 2 (PM + SI) | Same 2 (PM + SI) |
| Tasks | Fewer | More comprehensive |
| Documents | Fewer, simpler | Structured, more detailed |
| Traceability | Minimal | Required |
| Team size | 1-3 people | Up to 25 people |

**Key finding:** Entry and Basic have the SAME two processes (PM and SI) and the SAME activity names. The difference is the **number of tasks and number of required documents** is lower in Entry.

For AI agent teams (AEGIS context): Basic profile is appropriate — it targets exactly "a single application developed by a single work team."

Sources:
- https://handwiki.org/wiki/ISO_29110
- https://www.iapp.co.th/blog/what-is-iso-29110-complete-guide

---

## FINDING 3: The ACTUAL Process Flow — Basic Profile

### Two Processes Only

ISO 29110 Basic Profile defines exactly **two processes**:
1. **PM — Project Management Process** (4 activities)
2. **SI — Software Implementation Process** (6 activities)

Everything else (infrastructure, HR, training) is out of scope for this standard.

### PM Process: 4 Activities

**PM.1 — Project Planning**
- Input: Statement of Work (from customer)
- Tasks: Define scope, identify deliverables, select lifecycle, assign roles, identify risks, create version management strategy, set up project repository
- Output: Project Plan, Meeting Record, Project Repository (initial)

**PM.2 — Project Plan Execution**
- Input: Project Plan [accepted], Change Requests
- Tasks: Monitor progress against plan, evaluate change requests with impact analysis, conduct internal/external review meetings, maintain version control, update project repository
- Output: Progress Status Record, Change Request [evaluated], Meeting Records, Project Plan [updated], Software Configuration items

**PM.3 — Project Assessment and Control**
- Input: Project Plan [updated], Progress Status Record
- Tasks: Evaluate actual vs planned performance, establish corrective actions
- Output: Progress Status Record [evaluated], Correction Register

**PM.4 — Project Closure**
- Input: Project Plan, Validation Report, Delivered product
- Tasks: Formalize project completion per delivery instructions, update repository baseline
- Output: Acceptance Record (signed by customer), Project Repository [baselined]

### SI Process: 6 Activities

**SI.1 — Software Implementation Initiation**
- Input: Project Plan
- Tasks: Review project plan with team, set up implementation environment, establish development tools
- Output: Project Plan [reviewed], Implementation Environment

**SI.2 — Software Requirements Analysis**
- Input: Statement of Work, Project Plan
- Tasks: Elicit and define software requirements, analyze for correctness and testability, get customer approval, baseline requirements
- Output: Software Requirements Specification [baselined, customer-approved], Requirements Traceability Matrix (initial)

**SI.3 — Software Architectural and Detailed Design**
- Input: Software Requirements Specification [baselined]
- Tasks: Develop architectural design, develop detailed design for each component, verify design against requirements, update traceability
- Output: Software Design Document [baselined], Requirements Traceability Matrix [updated]

**SI.4 — Software Construction**
- Input: Software Design Document [baselined]
- Tasks: Produce software components per design, write and execute unit tests, correct defects
- Output: Software Components [unit tested], Test Cases and Test Procedures

**SI.5 — Software Integration and Testing**
- Input: Software Components [unit tested], Software Design Document
- Tasks: Integrate components, execute integration tests, execute system tests, verify against requirements, validate against customer needs, correct defects
- Output: Software [integrated, tested], Test Report, Verification Results, Validation Results

**SI.6 — Product Delivery**
- Input: Software [validated], Project Plan, User documentation
- Tasks: Package deliverables per delivery instructions, deliver to customer, get customer acceptance
- Output: Software Configuration [delivered], User Manual [if required], Acceptance Record [submitted to PM]

**Key insight:** SI.6 feeds the Acceptance Record back to PM.4 to formally close the project.

Sources:
- https://gist.github.com/dtinth/7260316 (lecture notes, detailed breakdown)
- https://pdfcoffee.com/technical-iso-iec-tr-29110-5-6-1-pdf-free.html (Systems Engineering variant for comparison)
- Multiple ResearchGate figures confirming structure

---

## FINDING 4: Complete List of Required Work Products — Basic Profile

### PM Process Work Products

| Work Product | Created In | Required |
|-------------|-----------|---------|
| Project Plan | PM.1 | YES — normative |
| Meeting Record | PM.1, PM.2 | YES — every formal meeting |
| Progress Status Record | PM.2, PM.3 | YES — regular tracking |
| Change Request | PM.2 | YES — for every scope change |
| Correction Register | PM.3 | YES — defect/issue tracking |
| Project Repository | PM.1 through PM.4 | YES — version-controlled archive |
| Acceptance Record | PM.4 | YES — customer signature required |

### SI Process Work Products

| Work Product | Created In | Required |
|-------------|-----------|---------|
| Software Requirements Specification | SI.2 | YES — normative |
| Requirements Traceability Matrix | SI.2–SI.5 | YES — links req→design→test |
| Software Design Document | SI.3 | YES — architecture + detail |
| Software Components (source code) | SI.4 | YES |
| Test Cases and Test Procedures | SI.4–SI.5 | YES |
| Test Report | SI.5 | YES |
| Verification Results | SI.5 | YES |
| Validation Results | SI.5 | YES |
| User Manual | SI.6 | YES (if contractually required) |
| Software Configuration (deliverable set) | SI.6 | YES |

### External Input (not created by VSE)

| Work Product | Source |
|-------------|--------|
| Statement of Work | Customer — triggers everything |

### Total: ~17 distinct work products for Basic Profile

**Critical distinction:** The standard does NOT prescribe the FORMAT or FORM of these documents. A project plan can be a markdown file, a spreadsheet, or a formal doc — the standard only requires the CONTENT to address defined topics.

Sources:
- https://gist.github.com/dtinth/7260316
- https://www.iapp.co.th/blog/what-is-iso-29110-complete-guide
- Academic synthesis from multiple ResearchGate publications

---

## FINDING 5: What Documents Are Created WHEN in the Lifecycle

```
PROJECT START
    |
    ▼
[Statement of Work received from Customer]
    |
    ▼
PM.1: Project Plan created ──────────────────► Project Plan
PM.1: Repository initialized ───────────────► Project Repository
PM.1: Kick-off meeting ──────────────────────► Meeting Record #1
    |
    ▼
SI.1: Team reviews plan ─────────────────────► Project Plan [reviewed]
SI.1: Dev environment set up ────────────────► Implementation Environment
    |
    ▼
SI.2: Requirements elicited ─────────────────► Requirements Specification
SI.2: Customer approves requirements ────────► Requirements [baselined]
SI.2: Traceability started ──────────────────► Traceability Matrix (v1)
    |
    ▼  ◄── PM.2 starts here (ongoing)
    |       Progress Status Record (regular)
    |       Meeting Records (regular)
    |       Change Requests (as needed)
    |       Correction Register (as needed)
    ▼
SI.3: Architecture designed ─────────────────► Design Document
SI.3: Traceability updated ──────────────────► Traceability Matrix (v2)
    |
    ▼
SI.4: Code written ──────────────────────────► Software Components
SI.4: Unit tests written/run ────────────────► Test Cases + Procedures
    |
    ▼
SI.5: Integration testing ───────────────────► Test Report
SI.5: Verification ──────────────────────────► Verification Results
SI.5: Validation ────────────────────────────► Validation Results
    |
    ▼
SI.6: Packaged for delivery ─────────────────► Software Configuration
SI.6: User Manual (if required) ─────────────► User Manual
SI.6: Acceptance submitted ──────────────────► Acceptance Record (draft)
    |
    ▼  ◄── PM.3 runs throughout (periodic)
    |       Corrective actions tracked
    ▼
PM.4: Acceptance signed ─────────────────────► Acceptance Record (signed)
PM.4: Repository baselined ──────────────────► Project Repository [final]

PROJECT CLOSED
```

**PM.2 and PM.3 are ONGOING throughout the project, not sequential steps.**

---

## FINDING 6: How Iterations/Sprints Map to ISO 29110

### Official Position
ISO 29110 explicitly states it does NOT preclude: waterfall, iterative, incremental, evolutionary, or agile. Part 5-4:2025 is a new dedicated Agile guideline.

### Agile-29110 Mapping (from Thai JIST paper + academic research)

| Scrum Event/Artifact | ISO 29110 Mapping |
|---------------------|-------------------|
| Product Backlog | Initial Requirements Specification (SI.2) |
| Sprint Planning | PM.2 task assignment + SI activity selection |
| Sprint (iteration) | Subset of SI.3, SI.4, SI.5 per sprint scope |
| Sprint Review | PM.2 review meeting + Verification Results |
| Sprint Retrospective | PM.3 assessment, Correction Register update |
| Sprint Backlog | Project Plan decomposed tasks |
| Definition of Done | Verification criteria in Test Cases |
| Increment | Updated Software Components + Test Report |
| Release | SI.6 Product Delivery |

### Key mapping principle
Each sprint should produce **updated versions** of relevant work products, not brand-new documents. The Requirements Traceability Matrix is critical — it links user stories (requirements) to design to tests across all sprints.

### One project plan, updated iteratively
A single Project Plan is created in PM.1, then UPDATED throughout PM.2 as sprints complete. The plan is not re-created from scratch each sprint.

Sources:
- https://ph02.tci-thaijo.org/index.php/JIST/article/view/187845
- https://www.iso.org/standard/82668.html (Part 5-4:2025 Agile)
- https://www.researchgate.net/publication/326271657 (Agile-ISO 29110 at Canadian bank)
- https://li01.tci-thaijo.org/index.php/sehs/article/view/257969 (Traceability model paper)

---

## FINDING 7: Thailand ISO 29110 Implementation

### Scale of Adoption
- Between 2012–2015: 274 private + 13 public organizations certified
- By most recent data: 320+ private + 15+ public organizations certified to Basic profile
- Thailand is one of the most active ISO 29110 adopter nations globally

### Key Enablers (SIPA/DEPA role)
- SIPA (Software Industry Promotion Agency, now DEPA) ran a national program
- SIPA provided: staff training, consultation, mentors, and PAID THE CERTIFICATION FEE for eligible companies
- Program specifically targeted Thai SMEs and software houses wanting to access government contracts

### Thai Certification Body
- URS Thailand (URS Holdings) is an active certification body in Thailand
- iApp Technology — example Thai company certified to 29110-4-1:2018, valid through March 2028
- Smart Finder, ASUENE Thailand — other certified Thai companies

### Factors Affecting Thai Adoption (from academic study)
Positive factors: IT experience, top management support
Negative factors (barriers): competitive pressure, perceived difficulty, user training costs

Sources:
- https://www.ursthailand.com/iso-29110-4-12018-certification-software-life-cycle-profiles-and-guidelines-for-very-small-entities-vses/
- https://asuene.com/us/news/asuene-thailand-achieves-iso-iec-29110-certification-for-software-development
- https://www.researchgate.net/figure/ISO-IEC-29110-Basic-Profile-certified-organizations-in-Thailand_tbl1_310445322
- https://standard.etda.or.th/?p=214

---

## FINDING 8: ISO 29110 vs ISO 12207 — Key Differences

| Aspect | ISO 29110 (Basic) | ISO 12207 |
|--------|------------------|-----------|
| Target | VSEs, 1-25 people | Medium/large organizations |
| Processes | 2 (PM + SI) | 43 processes across 6 categories |
| Tailoring required | No — pre-tailored subset | Yes — must select and tailor |
| Lifecycle flexibility | Yes (any lifecycle) | Yes |
| Certification cost | Low | High |
| Free version available | Yes (Part 5-1-2) | No |
| Documentation overhead | Low | High |

**Formal relationship:** ISO 29110 Basic Profile is explicitly a pre-tailored **subset** of ISO 12207. It selects the Project Management and Software Implementation process elements from ISO 12207. Work products come from ISO 15289.

Sources:
- https://www.topsoftwaredevelopers.de/s/en/ISO+Standards+for+Software+Development/16575

---

## FINDING 9: Deployment Packages (Free Implementation Guides)

Deployment Packages are collections of ready-to-use artifacts (templates, checklists, guides) to help VSEs implement specific activities of ISO 29110.

### Known Deployment Packages for Basic Profile

1. **Requirements Analysis** — covering SI.2
2. **Architecture and Detailed Design** — covering SI.3
3. **Construction and Unit Testing** — covering SI.4
4. **Integration and Testing** — covering SI.5
5. **Verification and Validation** — covering SI.5
6. **Version Control** — covering project repository management
7. **Project Management** — covering PM.1–PM.4
8. **Product Delivery** — covering SI.6
9. **Self-Assessment** — for gap analysis before certification

**Developed by:** Prof. Claude Y. Laporte (ETS Montreal) in collaboration with CETIC (Belgium)

**Where to get them:** http://profs.etsmtl.ca/claporte/english/vse/vse-packages.html (redirects to ETS Montreal site — some pages return 404 as of 2026)

**CETIC involvement:** CETIC (Belgium) specifically co-developed the Software Requirement Analysis Deployment Package.

Sources:
- https://www.cetic.be/Software-lifecycle-for-Very-Small
- http://profs.etsmtl.ca/claporte/english/vse/vse-packages.html

---

## FINDING 10: What Auditors Actually Check

### Certification Scheme (ISO/IEC 29110-3-2:2018)

ISO 29110 uses **process certification** (not management system certification, not product certification). The auditor evaluates whether the VSE's actual processes conform to the profile specifications.

### Four-Stage Certification Process

1. **Gap Analysis** — VSE assesses current state against Basic profile requirements
2. **Implementation** — VSE implements or improves processes to address gaps
3. **Internal Assessment** — VSE verifies own conformity using self-assessment checklist
4. **External Audit** — Certification body performs audit; issues certificate if conformant

### What Auditors Check

Based on research synthesis:

1. **Work product existence** — Can the VSE produce the actual artifacts (Project Plan, Requirements Spec, Design Doc, Test Report, Acceptance Record)?
2. **Work product content** — Do the artifacts cover the topics specified in the standard?
3. **Process evidence** — Meeting records, progress status records proving PM.2/PM.3 happened
4. **Traceability** — Does the Requirements Traceability Matrix actually link requirements → design → tests?
5. **Change management** — Are Change Requests documented and evaluated?
6. **Version control** — Is there a project repository with version history?
7. **Customer sign-off** — Is there a real Acceptance Record signed by the customer?
8. **Conformity of activities** — Did the team actually follow the activity sequence, or just produce documents after the fact?

**Critical audit finding from research:** VSEs often focus on producing documents but auditors assess compliance based on **detailed activities and tasks** — not just document existence. There is a common disconnect: teams produce all the right documents but cannot demonstrate the PROCESS was actually followed.

Sources:
- https://www.iso.org/standard/62732.html (Part 3-2:2018 Certification scheme)
- https://www.iso.org/standard/64781.html (Part 3-3:2016 Certification requirements)
- Research synthesis from Irish, Peruvian, and Thai case studies

---

## FINDING 11: Common Mistakes Teams Make

From multiple case studies (Ireland, Peru, Thailand, Ecuador):

1. **Documentation-first mindset** — Producing documents to satisfy the standard rather than using them to guide work. Auditors can detect this.

2. **Treating PM and SI as sequential** — PM.2, PM.3 run CONCURRENTLY with all SI activities. Many teams close PM.2 before finishing SI activities.

3. **One-time project plan** — Treating the Project Plan as a document created at start and never updated. The standard requires it to be maintained and updated throughout PM.2.

4. **Missing traceability** — Creating requirements spec and design doc as separate silos with no Requirements Traceability Matrix linking them.

5. **Skipping Change Requests for small changes** — Any scope/requirement change must go through a Change Request with impact evaluation. "Small" changes without documentation are audit failures.

6. **No meeting records** — Informal reviews (code review, design review) not documented. Every formal review/meeting requires a Meeting Record.

7. **Acceptance Record not formally signed** — Getting verbal customer approval but no written Acceptance Record. This is a PM.4 requirement.

8. **Time constraints** — Especially for agile teams, the documentation overhead feels burdensome. The key is integrating documentation INTO the workflow, not adding it after.

9. **Improper project selection for pilot** — Choosing too large or too complex a project for first certification. Recommendation: use a small, real customer project (~500-1000 hours).

10. **Confusing the standard level** — Attempting Intermediate profile when Basic is sufficient, or using Basic when Entry would be more appropriate for a startup with tiny projects.

Sources:
- https://www.researchgate.net/publication/289024012 (Irish pilot study)
- https://ieeexplore.ieee.org/document/7530452/ (Lima, Peru case study)
- https://www.researchgate.net/publication/307586580 (Multi-case analysis)
- Academic synthesis from Thailand adoption study

---

## FINDING 12: Required vs. Optional Documents — Definitive Breakdown

### Definitively Required (normative, auditors will check)
- Project Plan
- Software Requirements Specification (customer-approved + baselined)
- Software Design Document (architectural + detailed)
- Test Cases and Test Procedures
- Test Report
- Acceptance Record (customer-signed)
- Progress Status Record (per monitoring period)
- Meeting Record (for all formal reviews)
- Change Request (for every change)
- Correction Register
- Project Repository (with version history)
- Requirements Traceability Matrix

### Conditionally Required (based on contract/project type)
- User Manual — required "if contractually required"
- Verification Results — part of test report in many implementations
- Validation Results — may be embedded in Test Report

### Not Required by the Standard (but common practice)
- Risk Register (risks are documented IN the Project Plan, not separate)
- Quality Plan (quality activities are part of the Project Plan)
- Configuration Management Plan (strategy is part of Project Plan)
- Sprint/Iteration Plan (not named by standard — maps to Project Plan tasks)

**The standard does not require these as separate documents** — their content is typically embedded in the Project Plan or other required documents.

Sources:
- https://gist.github.com/dtinth/7260316 (lecture notes with explicit outputs per activity)
- https://www.iapp.co.th/blog/what-is-iso-29110-complete-guide

---

## FINDING 13: AEGIS Compliance Assessment — Preliminary Gaps

Based on research, these are the areas where AEGIS's ISO 29110 implementation should be verified against the actual standard:

### Areas Likely Correct
- Two-process structure (PM + SI) — consistent with standard
- Activity naming (Planning, Execution, Assessment, Closure for PM)
- Agile/iterative lifecycle compatibility — confirmed by standard
- Basic profile applicability for small team — confirmed

### Areas to Verify
1. **Requirements Traceability Matrix** — does AEGIS explicitly create and maintain this? It is normative.
2. **Change Request process** — is there a formal CR evaluation step with impact assessment?
3. **Meeting Records** — are all sprint reviews and design reviews generating formal meeting records?
4. **Project Repository baseline** — is there a formal baselining step at closure?
5. **Customer Acceptance Record** — for AEGIS operating on real projects, is there a formal sign-off artifact?
6. **PM.3 frequency** — how often is Project Assessment and Control actually run? Must be periodic, not just at closure.

### Not in Scope for Basic Profile (AEGIS should not over-engineer)
- Infrastructure management process
- Human resource management
- Organizational quality management
- Supply chain management
- These appear only at Intermediate/Advanced profiles

---

## REFERENCES AND SOURCES

### ISO Official Standards
- [ISO/IEC 29110-4-1:2018 Profile Specifications](https://www.iso.org/standard/67223.html)
- [ISO/IEC 29110-5-1-2:2025 Basic Profile Guidelines (FREE)](https://www.iso.org/standard/82669.html)
- [ISO/IEC 29110-5-1-1:2025 Entry Profile Guidelines](https://www.iso.org/standard/85420.html)
- [ISO/IEC 29110-5-4:2025 Agile Guidelines](https://www.iso.org/standard/82668.html)
- [ISO/IEC 29110-3-2:2018 Certification Scheme](https://www.iso.org/standard/62732.html)
- [ISO/IEC 29110-3-3:2016 Certification Requirements](https://www.iso.org/standard/64781.html)
- [ISO/IEC 29110 Series Overview](https://committee.iso.org/sites/jtc1sc7/home/projects/flagship-standards/isoiec-29110-series.html)

### Academic and Implementation Resources
- [ISO 29110 Lecture Notes (GitHub)](https://gist.github.com/dtinth/7260316) — Contains PM/SI work product list
- [ISO 29110 Encyclopedia MDPI](https://encyclopedia.pub/entry/33199)
- [ISO 29110 HandWiki](https://handwiki.org/wiki/ISO_29110)
- [Formal Mind Blog — Part 1 Overview](https://www.formalmind.com/blog/isoiec-29110-part-1-lightweight-standard-based-software-and-systems-engineering/)
- [CETIC Deployment Packages](https://www.cetic.be/Software-lifecycle-for-Very-Small)
- [Prof. Laporte VSE Packages Page](http://profs.etsmtl.ca/claporte/english/vse/vse-packages.html)

### Thailand-Specific Resources
- [iApp Technology — Thai ISO 29110 Guide](https://www.iapp.co.th/blog/what-is-iso-29110-complete-guide)
- [URS Thailand Certification](https://www.ursthailand.com/iso-29110-4-12018-certification-software-life-cycle-profiles-and-guidelines-for-very-small-entities-vses/)
- [ETDA Thailand ISO 29110 Article](https://standard.etda.or.th/?p=214)
- [ASUENE Thailand Certification](https://asuene.com/us/news/asuene-thailand-achieves-iso-iec-29110-certification-for-software-development)
- [Thai Government Adoption Factors Paper](https://www.etsmtl.ca/etudier-a-lets/corps-enseignant/claporte/Publications/Publications/Factors%20Influencing%20the%20Adoption%20of%20ISO%20IEC%2029110%20in%20Thai%20Government%20Projects.pdf)

### Case Studies
- [Peru Startup Certification](https://www.academia.edu/56881027/Implementation_and_Certification_of_ISO_IEC_29110_in_an_IT_Startup_in_Peru)
- [Lima VSE Implementation — IEEE](https://ieeexplore.ieee.org/document/7530452/)
- [Irish Pilot Implementation — Springer](https://link.springer.com/chapter/10.1007/978-3-642-38833-0_23)
- [Multi-case Analysis — ResearchGate](https://www.researchgate.net/publication/307586580_A_Multi-case_Study_Analysis_of_Software_Process_Improvement_in_Very_Small_Companies_Using_ISOIEC_29110)
- [Agile VSE Case Study — ResearchGate](https://www.researchgate.net/publication/346786179_A_Case_Study_of_Improving_a_Very_Small_Entity_with_an_Agile_Software_Development_Based_on_the_Basic_Profile_of_the_ISOIEC_29110)
- [Agile-ISO 29110 at Canadian Bank](https://www.researchgate.net/publication/326271657_Implementation_of_an_Agile-ISO_29110_Software_Process_in_a_Large_Canadian_Financial_Institution)

### Agile Mapping
- [Thai JIST — Agile ISO 29110 Experience](https://ph02.tci-thaijo.org/index.php/JIST/article/view/187845)
- [Agile Traceability Model — Thai Journal](https://li01.tci-thaijo.org/index.php/sehs/article/view/257969)
- [Agile Compliance Analysis — ScienceDirect](https://www.sciencedirect.com/science/article/pii/S1877050915026150)

---

## SUMMARY: Key Facts for AEGIS ISO 29110 Implementation

1. **Basic Profile = 2 processes only**: PM (4 activities) and SI (6 activities). No other processes are required.

2. **12 required work products** (core): Project Plan, Requirements Spec, Design Doc, Test Cases, Test Report, Acceptance Record, Progress Status Records, Meeting Records, Change Requests, Correction Register, Project Repository, Requirements Traceability Matrix.

3. **PM.2 and PM.3 are ongoing** — they run in parallel with all SI activities, not sequentially after them.

4. **Agile is explicitly supported** — Part 5-4:2025 now provides dedicated agile guidelines. Sprint = iterative execution of SI activities. Project Plan is updated each sprint.

5. **Thailand has 320+ certified organizations** — Standard is well-tested in Thai context. DEPA/SIPA programs actively support certification.

6. **Free download available** — ISO/IEC 29110-5-1-2:2025 (Basic profile guidelines) is freely available from ISO/ITTF. This is the authoritative implementation guide.

7. **Auditors check processes, not just documents** — The most critical audit failure mode is having documents without being able to demonstrate the process was actually followed.

8. **Format is flexible** — The standard does not prescribe document formats. Markdown files, wiki pages, or formal documents are all acceptable if content requirements are met.

