# Message Types — Inter-Agent Communication Protocol

> Structured message protocol for agent-to-agent communication within AEGIS.
> Agents use these as structured sections in their messages, not raw JSON.

## Message Format

All inter-agent messages follow this structure:

```
--- [MESSAGE_TYPE] ---
From: [agent_emoji] [agent_name]
To: [agent_emoji] [agent_name] (or "all")
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [critical | high | normal | low]
---
[Message body with type-specific fields]
---
```

## Message Type Definitions

### TaskAssignment
Sent by Navi to delegate work to an agent.

```
--- TaskAssignment ---
From: 🧭 Navi
To: [target agent]
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [critical | high | normal | low]
---
Task: [clear description of what needs to be done]
Context: [relevant background, file paths, prior findings]
Deadline: [expected completion, or "ASAP"]
Acceptance criteria: [how to know the task is done]
Dependencies: [other tasks or agents this depends on]
---
```

### StatusUpdate
Sent by any agent to report progress on an assigned task.

```
--- StatusUpdate ---
From: [agent]
To: 🧭 Navi
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: normal
---
Task ID: [reference to TaskAssignment]
Status: [WORKING | BLOCKED | ERROR | DONE | WAITING]
Progress: [percentage or step X/Y]
Summary: [what was accomplished since last update]
Blockers: [list of blockers, or "none"]
Next: [what will happen next]
---
```

### FindingReport
Sent by review/research agents to report discoveries.

```
--- FindingReport ---
From: [agent]
To: [target agent or "all"]
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [based on highest severity finding]
---
Category: [security | performance | correctness | design | data]
Findings:
  - [severity_emoji] [description] @ [location]
  - [severity_emoji] [description] @ [location]
Evidence: [file paths, code references, data sources]
Recommendation: [suggested action]
---
```

### PlanProposal
Sent by Sage (or Navi) to propose a plan of action.

```
--- PlanProposal ---
From: [agent]
To: 🧭 Navi (+ relevant agents)
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [high | normal]
---
Plan summary: [1-2 sentence overview]
Steps:
  1. [step description] — assigned to [agent] — est. [tokens/time]
  2. [step description] — assigned to [agent] — est. [tokens/time]
Risks:
  - [risk description] — mitigation: [mitigation]
Estimated total tokens: [number]
Requires approval: [yes/no]
---
```

### ApprovalRequest
Sent when an action requires human or lead approval.

```
--- ApprovalRequest ---
From: [agent]
To: 🧭 Navi (or Human)
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [critical | high | normal]
---
Action: [what is being requested]
Risk level: [high | medium | low]
Requires human: [true | false]
Rationale: [why this action is proposed]
Alternatives: [other options considered]
Deadline: [when approval is needed by]
---
```

### EscalationAlert
Sent when an agent encounters an issue beyond their authority.

```
--- EscalationAlert ---
From: [agent]
To: 🧭 Navi
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [critical | high]
---
Issue: [description of the problem]
Severity: [critical | high]
Impact: [what happens if not addressed]
Suggested action: [what the agent recommends]
Blocking: [list of tasks/agents blocked by this]
---
```

### QualityGate
Sent by Vigil after completing a review.

```
--- QualityGate ---
From: 🛡️ Vigil
To: 🧭 Navi
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: [based on result]
---
Gate name: [e.g., "Pre-merge review", "Spec approval"]
Status: [PASS | FAIL | CONDITIONAL]
Summary: [1-2 sentence verdict]
Critical findings: [count]
Warnings: [count]
Consensus: [which agents reviewed and their verdicts]
Report: [path to full review report]
---
```

### SessionSummary
Sent by Navi at the end of a session.

```
--- SessionSummary ---
From: 🧭 Navi
To: all
Timestamp: YYYY-MM-DD HH:MM UTC
Priority: normal
---
Completed:
  - [task description] — [agent] — [outcome]
Pending:
  - [task description] — [agent] — [status]
Blockers:
  - [blocker description] — [owner]
Lessons learned:
  - [insight from this session]
Next session priorities:
  - [priority item]
---
```

## Routing Rules

1. All messages pass through Navi unless agents are in the same task group
2. Critical and high priority messages are processed immediately
3. Normal and low priority messages are batched when possible
4. EscalationAlerts always go to Navi, regardless of routing
5. SessionSummary is broadcast to all agents
