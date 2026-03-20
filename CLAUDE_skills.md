# AEGIS v6.0 -- Skill Catalog

> Skills are loaded on-demand based on the active profile. Never load all skills at once.

---

## Profile Tiers

| Profile | Skill Count | Context Cost | Use When |
|---------|-------------|--------------|----------|
| minimal | 7 | ~3K tokens | Quick tasks, small projects, limited context |
| standard | 13 | ~6K tokens | Normal development, team projects |
| full | 21+ | ~12K tokens | Complex analysis, full pipeline, enterprise |

---

## Minimal Profile (7 skills)

### 1. personas
- **Description**: Load and activate AEGIS agent personas with model routing
- **Profile**: minimal
- **Triggers EN**: "persona", "agent", "spawn", "team"
- **Triggers TH**: "ตัวตน", "เอเจนต์", "สร้างทีม"
- **File**: skills/ai-personas.md

### 2. orchestrator
- **Description**: Pipeline orchestration, task routing, agent coordination
- **Profile**: minimal
- **Triggers EN**: "orchestrate", "pipeline", "coordinate", "plan"
- **Triggers TH**: "จัดการ", "ประสานงาน", "วางแผน"
- **File**: skills/orchestrator.md

### 3. code-review
- **Description**: Structured code review with severity ratings and checklists
- **Profile**: minimal
- **Triggers EN**: "review", "code review", "PR review", "check code"
- **Triggers TH**: "รีวิว", "ตรวจโค้ด", "ตรวจสอบ"
- **File**: skills/code-review.md

### 4. code-standards
- **Description**: Enforce coding standards, linting rules, style conventions
- **Profile**: minimal
- **Triggers EN**: "standards", "lint", "style", "convention", "format"
- **Triggers TH**: "มาตรฐาน", "รูปแบบโค้ด", "สไตล์"
- **File**: skills/code-standards.md

### 5. git-workflow
- **Description**: Git branching, commit conventions, PR workflow management
- **Profile**: minimal
- **Triggers EN**: "git", "branch", "commit", "PR", "merge"
- **Triggers TH**: "กิต", "สาขา", "คอมมิต", "รวมโค้ด"
- **File**: skills/git-workflow.md

### 6. bug-lifecycle
- **Description**: Bug triage, reproduction, root cause analysis, fix verification
- **Profile**: minimal
- **Triggers EN**: "bug", "fix", "debug", "issue", "error", "crash"
- **Triggers TH**: "บัก", "แก้ไข", "ข้อผิดพลาด", "ดีบัก"
- **File**: skills/bug-lifecycle.md

### 7. project-navigator
- **Description**: Explore project structure, find files, understand codebase layout
- **Profile**: minimal
- **Triggers EN**: "navigate", "find", "explore", "structure", "where is"
- **Triggers TH**: "นำทาง", "หา", "สำรวจ", "โครงสร้าง"
- **File**: skills/project-navigator.md

---

## Standard Profile (13 skills = minimal + 6)

### 8. super-spec
- **Description**: Generate comprehensive feature specifications from requirements
- **Profile**: standard
- **Triggers EN**: "spec", "specification", "requirements", "feature spec"
- **Triggers TH**: "สเปค", "ข้อกำหนด", "ความต้องการ"
- **File**: skills/super-spec.md

### 9. test-architect
- **Description**: Design test strategy, generate test cases, coverage analysis
- **Profile**: standard
- **Triggers EN**: "test", "testing", "coverage", "test plan", "QA"
- **Triggers TH**: "ทดสอบ", "เทสต์", "ครอบคลุม", "แผนทดสอบ"
- **File**: skills/test-architect.md

### 10. security-audit
- **Description**: Security vulnerability scanning, threat modeling, OWASP checks
- **Profile**: standard
- **Triggers EN**: "security", "audit", "vulnerability", "OWASP", "CVE"
- **Triggers TH**: "ความปลอดภัย", "ตรวจสอบ", "ช่องโหว่", "ภัยคุกคาม"
- **File**: skills/security-audit.md

### 11. tech-debt-tracker
- **Description**: Identify, categorize, and prioritize technical debt items
- **Profile**: standard
- **Triggers EN**: "tech debt", "refactor", "cleanup", "legacy", "TODO"
- **Triggers TH**: "หนี้เทคนิค", "ปรับปรุง", "ทำความสะอาด"
- **File**: skills/tech-debt-tracker.md

### 12. sprint-tracker
- **Description**: Sprint planning, velocity tracking, standup summaries
- **Profile**: standard
- **Triggers EN**: "sprint", "velocity", "standup", "backlog", "kanban"
- **Triggers TH**: "สปรินต์", "ความเร็ว", "แบคล็อก", "งานค้าง"
- **File**: skills/sprint-tracker.md

### 13. api-docs
- **Description**: Generate API documentation from code, OpenAPI/Swagger specs
- **Profile**: standard
- **Triggers EN**: "API", "docs", "swagger", "OpenAPI", "endpoint"
- **Triggers TH**: "เอพีไอ", "เอกสาร", "จุดเชื่อมต่อ"
- **File**: skills/api-docs.md

---

## Full Profile (21+ skills = standard + 8)

### 14. aegis-distill
- **Description**: Compress conversation context into essential summaries
- **Profile**: full
- **Triggers EN**: "distill", "compress", "summarize context", "reduce tokens"
- **Triggers TH**: "กลั่น", "บีบอัด", "สรุปบริบท"
- **File**: skills/aegis-distill.md

### 15. aegis-observe
- **Description**: Monitor agent performance, token usage, and pipeline health
- **Profile**: full
- **Triggers EN**: "observe", "monitor", "health", "metrics", "dashboard"
- **Triggers TH**: "สังเกต", "ตรวจสอบ", "สุขภาพระบบ", "เมตริก"
- **File**: skills/aegis-observe.md

### 16. adversarial-review
- **Description**: Red-team analysis, adversarial testing, assumption challenging
- **Profile**: full
- **Triggers EN**: "adversarial", "red team", "challenge", "devil's advocate"
- **Triggers TH**: "ท้าทาย", "ตั้งคำถาม", "ทดสอบสมมติฐาน"
- **File**: skills/adversarial-review.md

### 17. code-coverage
- **Description**: Analyze test coverage, identify untested paths, coverage goals
- **Profile**: full
- **Triggers EN**: "coverage", "untested", "coverage report", "gaps"
- **Triggers TH**: "ครอบคลุม", "ไม่ได้ทดสอบ", "รายงานครอบคลุม"
- **File**: skills/code-coverage.md

### 18. retrospective
- **Description**: Structured session retrospectives with actionable insights
- **Profile**: full
- **Triggers EN**: "retro", "retrospective", "lessons", "what went well"
- **Triggers TH**: "ย้อนมอง", "บทเรียน", "สิ่งที่ดี", "สิ่งที่ต้องปรับ"
- **File**: skills/retrospective.md

### 19. course-correction
- **Description**: Detect pipeline drift, suggest corrections, realign with goals
- **Profile**: full
- **Triggers EN**: "drift", "off track", "correction", "realign", "pivot"
- **Triggers TH**: "เบี่ยงเบน", "ออกนอกเส้น", "แก้ไขทิศทาง"
- **File**: skills/course-correction.md

### 20. skill-marketplace
- **Description**: Discover, install, and manage community-contributed skills
- **Profile**: full
- **Triggers EN**: "marketplace", "install skill", "new skill", "community"
- **Triggers TH**: "ตลาดทักษะ", "ติดตั้งทักษะ", "ชุมชน"
- **File**: skills/skill-marketplace.md

### 21. aegis-builder
- **Description**: Meta-skill to create new AEGIS skills from templates
- **Profile**: full
- **Triggers EN**: "build skill", "create skill", "skill template", "meta"
- **Triggers TH**: "สร้างทักษะ", "เทมเพลตทักษะ", "สร้างใหม่"
- **File**: skills/aegis-builder.md

---

## Skill Loading Protocol

### How Skills Are Loaded
1. User triggers a command or Navi detects a need
2. Match trigger words against the skill catalog
3. Check if skill is available in current profile tier
4. Load skill file into context (only when needed)
5. Execute skill logic
6. Unload when task completes (context reclaimed at next distill)

### Profile Switching
```
/aegis-mode minimal    # Load only 7 core skills
/aegis-mode standard   # Load 13 skills (default)
/aegis-mode full       # Load all 21+ skills
```

### Custom Profile
Users can create custom profiles by listing specific skills:
```
/aegis-mode custom personas,code-review,security-audit,test-architect
```

---

## Skill File Template

Every skill file follows this structure:
```markdown
# Skill: <name>
> Profile: <minimal|standard|full>
> Triggers: <comma-separated trigger words>

## Purpose
<1-2 sentence description>

## When to Use
<Conditions that activate this skill>

## Workflow
<Step-by-step process>

## Inputs
<What the skill needs>

## Outputs
<What the skill produces>

## Agent Routing
<Which agents are involved>

## Examples
<Usage examples>
```
