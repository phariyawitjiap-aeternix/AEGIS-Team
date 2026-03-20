---
name: aegis-team-debate
description: "Spawn debate team for architecture decisions — multi-perspective deliberation"
triggers:
  en: debate, architecture decision, team debate, decide
  th: ถกเถียง, ดีเบต, ตัดสินใจ
---

# /aegis-team-debate

## Quick Reference
Spawns a debate team for architecture/design decisions. Lead: Navi (facilitator),
Members: Sage (analytical), Bolt (pragmatic), Havoc (adversarial). Each presents their
perspective, Havoc challenges every proposal, Navi synthesizes consensus. Output: an
Architecture Decision Record (ADR) with pros/cons/decision/rationale, saved to
_aegis-brain/resonance/architecture-decisions.md.

## Full Instructions

### Step 1: Check tmux Availability
- Run `which tmux` to check if tmux is installed.
- If available: spawn parallel team.
- If not: run debate sequentially (each "agent" presents in turn).

### Step 2: Spawn Debate Team
- Create tmux session: `aegis-debate-[timestamp]`
- Team structure:
  - **Lead/Facilitator**: Navi (🧭 Orchestrator) — facilitates discussion, synthesizes consensus
  - **Member**: Sage (📖 Analyst) — analytical, evidence-based perspective
  - **Member**: Bolt (⚡ Speed) — pragmatic, implementation-focused perspective
  - **Member**: Havoc (💥 Adversarial) — challenges everything, finds flaws
- Accept the debate topic from the user.

### Step 3: Debate Execution

#### Round 1 — Opening Statements
Each member presents their perspective on the topic:

**Sage (Analytical Perspective):**
- Research the topic thoroughly.
- Present: best practices, industry standards, academic research.
- Cite: similar patterns in well-known projects.
- Recommend: the "textbook" approach with rationale.

**Bolt (Pragmatic Perspective):**
- Focus on implementation reality.
- Present: what's fastest to build, easiest to maintain.
- Consider: team capabilities, deadline, existing code.
- Recommend: the "get it done" approach with trade-offs acknowledged.

**Havoc (Adversarial Perspective):**
- Challenge BOTH Sage and Bolt's proposals.
- For each proposal, ask:
  - "What happens when this fails at scale?"
  - "What's the worst-case maintenance burden in 2 years?"
  - "What assumptions are you making that might be wrong?"
- Present: failure scenarios, hidden costs, overlooked risks.
- May propose an alternative that avoids the weaknesses of both.

#### Round 2 — Rebuttal
- Each member responds to challenges raised.
- Sage may strengthen or modify their recommendation.
- Bolt may acknowledge trade-offs or push back on theoretical concerns.
- Havoc continues to probe weaknesses.

#### Round 3 — Navi Facilitates Consensus
- Navi synthesizes all perspectives.
- Identifies:
  - Points of agreement (all three agree on these)
  - Points of contention (where they disagree)
  - Key trade-offs (what are we giving up with each option?)
- Proposes a decision that balances the perspectives.
- If no consensus: present the decision as "chosen approach" with documented dissent.

### Step 4: Generate Architecture Decision Record (ADR)
- Format:
  ```markdown
  # ADR: [Decision Title]
  
  **Date**: YYYY-MM-DD
  **Status**: Accepted
  **Deciders**: Navi (facilitator), Sage, Bolt, Havoc
  
  ## Context
  [What is the issue? Why does this decision need to be made?]
  
  ## Options Considered
  
  ### Option A: [Sage's recommendation]
  **Pros:**
  - [pro 1]
  - [pro 2]
  **Cons:**
  - [con 1 — from Havoc's challenge]
  - [con 2]
  
  ### Option B: [Bolt's recommendation]
  **Pros:**
  - [pro 1]
  - [pro 2]
  **Cons:**
  - [con 1 — from Havoc's challenge]
  - [con 2]
  
  ### Option C: [Alternative, if proposed]
  ...
  
  ## Decision
  [The chosen approach and why]
  
  ## Rationale
  [Why this option was selected over the others]
  
  ## Consequences
  - [What this means for the project going forward]
  - [What we're giving up]
  - [What we need to watch out for]
  
  ## Dissenting Opinions
  [If any agent strongly disagreed, note their concern here]
  ```

### Step 5: Save Decision
- Append the ADR to `_aegis-brain/resonance/architecture-decisions.md`.
- If the file doesn't exist, create it with a header:
  ```markdown
  # Architecture Decision Records
  
  This file contains architecture decisions made through AEGIS team debates.
  Each decision is an ADR (Architecture Decision Record) with full context.
  
  ---
  ```
- Also save individual ADR to `_aegis-brain/resonance/adr/YYYY-MM-DD_slug.md`.

### Step 6: Present to User
- Show a condensed summary:
  ```
  ┌─ Debate Result ──────────────────────────────┐
  │ Topic: [topic]                                │
  │ Decision: [chosen approach, 1 line]           │
  │                                               │
  │ Sage: [their position, 1 line]                │
  │ Bolt: [their position, 1 line]                │
  │ Havoc: [key concern, 1 line]                  │
  │                                               │
  │ Consensus: [yes/partial/no]                   │
  │ Saved: _aegis-brain/resonance/adr/...         │
  └───────────────────────────────────────────────┘
  ```
- Ask if user wants to modify the decision.
- Clean up tmux session.
