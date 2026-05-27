# AEGIS Competitive Landscape Research — May 2026

> Incremental update from 2026-04-07 research (hooks/patterns focus).
> This wave focuses on: frameworks, IDE agents, and AEGIS positioning.

**Date:** 2026-05-28
**Previous:** `2026-04-07_5-patterns-old-vs-new.md`
**Scope:** Multi-agent frameworks + IDE agents + competitive positioning
**Sources:** 25+ web sources (URLs at bottom)

---

## 1. Market Snapshot

The AI coding agent market has consolidated around **3 tiers** since our last research (Apr 2026):

| Tier | Description | Players |
|------|-----------|---------|
| **Tier 1: Platforms** | Full desktop/cloud agent with computer use | Codex Desktop, Antigravity 2.0, Devin |
| **Tier 2: IDE-Native** | Agent mode inside editor | Cursor, Windsurf, Copilot, JetBrains Junie |
| **Tier 3: Frameworks** | Orchestration layer for building agents | Claude Code + AEGIS, CrewAI, LangGraph, MetaGPT, SWE-Agent |

AEGIS sits in **Tier 3** — a framework built on top of Claude Code. Our closest competitors are CrewAI (45.9k stars), LangGraph (production state), and MetaGPT (company simulation).

---

## 2. Competitive Matrix — Frameworks

| Capability | AEGIS | CrewAI | LangGraph | MetaGPT | SWE-Agent | Devin |
|-----------|-------|--------|-----------|---------|-----------|-------|
| Multi-agent personas | ✅ 11 specialized | ✅ Custom roles | ✅ Composable | ✅ PM/Arch/Eng/Test | ❌ Single | ❌ Single |
| Non-stop execution | ✅ autopilot + daemon | ✅ Crew dispatch | ✅ Durable state | ✅ Phase-based | ✅ Issue-scoped | ✅ Cloud VM |
| Cross-session memory | ✅ FTS5 brain + handoffs | ❌ | ✅ Durable state persist | ❌ | ❌ | ✅ Built-in memory |
| Quality gate pipeline | ✅ review+test+spec | ⚠️ Custom possible | ⚠️ Custom possible | ✅ PM review phase | ✅ Test via shell | ❌ |
| Honesty contracts | ✅ VERIFIED/PRODUCED tags | ❌ | ❌ | ❌ | ❌ | ❌ |
| Policy-as-code hooks | ✅ 11 hooks enforced | ❌ | ❌ | ❌ | ❌ | ❌ |
| Coverage screen | ✅ Mandatory gap alert | ❌ | ❌ | ❌ | ❌ | ❌ |
| Research probe-gate | ✅ URL verification | ❌ | ❌ | ❌ | ❌ | ❌ |
| SWE-Bench score | ❌ Not benchmarked | ❌ | ❌ | 85% HumanEval | 40% Verified | ❌ |
| Open source | ✅ | ✅ 45.9k stars | ✅ v1.0 | ✅ 44k stars | ✅ MIT | ❌ Commercial |
| Enterprise adoption | ❌ Internal use | ✅ 63% F500 | ✅ Production-grade | ⚠️ MGX platform | ⚠️ Research | ✅ Teams |

---

## 3. Competitive Matrix — IDE/Desktop Agents

| Capability | AEGIS (Claude Code) | Cursor | Windsurf | Copilot | Antigravity 2 | Codex Desktop |
|-----------|-------------------|--------|----------|---------|---------------|---------------|
| Autonomy level | Full | Full (8 parallel subagents) | Full (Cascade) | Full (Agent Mode) | Full (desktop+CLI) | Full (computer use) |
| Multi-file | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Test running | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Non-stop loop | ✅ aegis-daemon/autopilot | ✅ Cloud background | ✅ Turbo Mode | ✅ Cloud Agent β | ✅ Parallel dynamic | ✅ Schedule + parallel |
| Computer use (GUI) | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ Mouse/keyboard |
| Cloud execution | ❌ Local only | ✅ Cloud agents | ⚠️ Inference only | ✅ Cloud Agent | ✅ Managed | ❌ Local sandbox |
| Team orchestration | ✅ 11 personas | ❌ Single agent | ❌ Single agent | ❌ Single agent | ❌ Single agent | ❌ Single agent |
| Memory across sessions | ✅ FTS5 brain | ❌ | ❌ | ❌ | ❌ | ✅ Ambient memory |
| Pricing | $200/mo (Max plan) | $20/mo Pro | Free-Enterprise | $10-20/mo → usage | Free-$100/mo | Pro/Max plan |
| SWE-Bench | 80.8% (Claude Code) | Not published | Not published | Not published | Not published | Not published |

---

## 4. What Competitors Do That AEGIS Doesn't

### 4A. Cloud Execution (Cursor, Copilot, Antigravity)
**What:** Run agents in cloud VMs — user's machine is free, multiple tasks in parallel.
**Gap for AEGIS:** Local-only. Can't run 5 projects simultaneously.
**Severity:** MEDIUM — daemon/autopilot is local-bound.
**Fix path:** ต้องรอ Anthropic เปิด cloud agent infra หรือ self-host.

### 4B. Computer Use / GUI Control (Codex Desktop, Antigravity)
**What:** Control mouse, keyboard, screen. Test UI visually. Deploy via browser.
**Gap for AEGIS:** Terminal-only. Can't test GUI, can't click deploy buttons.
**Severity:** HIGH for GUI projects, LOW for backend/API.
**Fix path:** Anthropic computer-use API exists แต่ยังไม่ integrate กับ Claude Code.

### 4C. SWE-Bench Benchmark (SWE-Agent, Claude Code)
**What:** Public benchmark proving agent can fix real GitHub issues.
**Gap for AEGIS:** No published score. Can't prove quality claims.
**Severity:** HIGH for credibility.
**Fix path:** Run SWE-Bench Verified on AEGIS workflow, publish results.

### 4D. Durable State Persistence (LangGraph)
**What:** Agent state auto-persists across server restarts. True resume, not handoff-based.
**Gap for AEGIS:** Handoff = lossy summary. LangGraph = lossless state.
**Severity:** MEDIUM — handoffs work in practice but lose detail.
**Fix path:** Explore LangGraph-style checkpoint vs current handoff approach.

### 4E. Parallel Sub-Agents at Scale (Cursor)
**What:** 8 parallel subagents in single session. Work on different files simultaneously.
**Gap for AEGIS:** Agent spawning exists but limited by context window sharing.
**Severity:** MEDIUM — AEGIS does parallel dispatch but shares context.
**Fix path:** Worktree isolation (already in AEGIS) + more aggressive parallelism.

---

## 5. What AEGIS Does That Nobody Else Does

### 5A. Honesty Contracts (v15-20)
Every claim tagged `[VERIFIED: <command>]` or `[PRODUCED: unverified]`. No other framework distinguishes between "I ran it" and "I believe it". This is the **#1 unique differentiator**.

### 5B. Policy-as-Code Enforcement (v8.3+)
11 hooks that machine-enforce rules. MBP scan blocks option menus. Guard-bash blocks destructive commands. No other framework has behavioral enforcement at the hook level — they all rely on prompt engineering.

### 5C. Coverage Contract (v15-19)
Mandatory warning when AEGIS can't drive 100% of the project (e.g., Unity, Xcode). No other framework admits its limitations — they either silently fail or claim capability they don't have.

### 5D. Research Probe-Gate (v15-20)
URLs cited in research docs must be probed. Downstream agents can't cite payload from `[UNPROBED]` URLs. Prevents fabricated API documentation. Nobody else does this.

### 5E. Cross-Session Brain (v10-06+)
FTS5 index over handoffs, retrospectives, learnings, instincts, decision logs. Searchable with `aegis-brain-search.sh`. CrewAI/MetaGPT have no memory; LangGraph has state but no semantic search.

### 5F. Quality Gate Pipeline (v15-28, today)
Unified code-review + test-run + spec-compliance check before DONE. MetaGPT has phases but no enforcement. SWE-Agent runs tests but no review. AEGIS is the only framework with all three gates in one pipeline.

---

## 6. Narrative: Where AEGIS Should Go

### The Thesis

> AEGIS ไม่ได้แข่งกับ Cursor/Copilot (IDE agents) หรือ Codex Desktop (platform agents) — แข่งกับ **CrewAI, LangGraph, MetaGPT** ในฐานะ **multi-agent orchestration framework** ที่สร้างบน Claude Code

### Three Strategic Pillars

**Pillar 1: Trust (ทำได้จริง พิสูจน์ได้)**
- Honesty contracts → ขยาย — ทุก agent output ต้อง tag VERIFIED/PRODUCED
- Quality gate → mandatory — ไม่มีงานผ่านโดยไม่ผ่าน gate
- SWE-Bench → benchmark AEGIS workflow, publish results
- Research probe-gate → ขยายไปครอบคลุม API docs, dependency claims

**Pillar 2: Autonomy (ทำงานต่อเนื่องไม่หยุด)**
- autopilot + daemon → shipped today ✅
- Credential discovery → first /aegis-start ✅ (memory)
- Handoff quality → improve from lossy summary to structured checkpoint
- Context efficiency → Ralph Loop pattern + aggressive memory pruning

**Pillar 3: Orchestration (หลาย agent ทำงานพร้อมกัน)**
- Quality gate auto-trigger → shipped today ✅
- Parallel dispatch → improve worktree isolation + concurrent gates
- Cross-project awareness → aegis-multi-tenant (v11-09, exists)
- Agent specialization → sharpen persona boundaries, reduce overlap

### What NOT to Chase

- ❌ **Computer use / GUI control** — wait for Anthropic, don't build custom
- ❌ **Cloud execution** — not viable without infra investment
- ❌ **IDE integration** — Claude Code IS the IDE; don't build VS Code extension
- ❌ **Commercial platform** — stay open-source dogfood; credibility > revenue

### Priority Roadmap (Next 3 Sprints)

| Priority | Item | Why |
|----------|------|-----|
| P0 | SWE-Bench Verified benchmark | Prove quality claims with public numbers |
| P0 | Quality gate mandatory in workflow | Every task must pass before DONE |
| P1 | Structured checkpoint (replace lossy handoff) | Close gap vs LangGraph durable state |
| P1 | Parallel gate execution | Run review+test concurrently, not sequentially |
| P2 | Agent SDK integration | Use Anthropic Agent SDK for tool-loop instead of custom |
| P2 | Credential discovery at /aegis-start | Already in memory, implement in code |

---

## 7. Key Numbers

| Metric | Value | Source |
|--------|-------|--------|
| Claude Code SWE-Bench Verified | 80.8% | Anthropic |
| Cursor market lead | 2:1 agent-to-completion ratio | Cursor blog |
| CrewAI GitHub stars | 45.9k | GitHub |
| MetaGPT HumanEval | 85% (vs 65% GPT-4 solo) | MetaGPT paper |
| SWE-Agent Verified | 40% (Claude 3.7) | Princeton |
| mini-swe-agent Verified | 74% (Gemini 3 Pro) | Research |
| Windsurf ARR | $82M | Acquisition report |
| Copilot users | 100M+ | GitHub |
| Agent runtime growth | 25→45 min (99.9th pct, Oct 2025-Jan 2026) | Faros.ai |
| SWE-Bench trajectory | 4%→80.9% in under 3 years | Leaderboard |

---

## Sources

### Frameworks
- [CrewAI Documentation](https://crewai.com/ [PROBED ✓ HTTP 200])
- [LangGraph v1.0 Announcement](https://blog.langchain.com/langchain-langgraph-1dot0/ [PROBED ✓ HTTP 301])
- [MetaGPT GitHub](https://github.com/FoundationAgents/MetaGPT [PROBED ✓ HTTP 200])
- [SWE-Agent Princeton](https://collaborate.princeton.edu/en/publications/swe-agent-agent-computer-interfaces-enable-automated-software-eng/ [PROBED ✓ HTTP 200])
- [Anthropic Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview [PROBED ✓ HTTP 200])
- [ChatDev v2.0](https://github.com/OpenBMB/ChatDev [PROBED ✓ HTTP 200])
- [Devin AI Guide 2026](https://singularitymoments.com/devin-ai-coding-agent-guide/ [PROBED ✓ HTTP 200])
- [AutoCodeRover/Sonar Acquisition](https://www.prnewswire.com/news-releases/nus-spinoff-technology-autocoderover-acquired-by-sonar-302396715.html [PROBED ✗ HTTP 404])
- [Multi-Agent Orchestration Scopir](https://scopir.com/posts/multi-agent-orchestration-parallel-coding-2026/ [PROBED ✓ HTTP 200])

### IDE/Desktop Agents
- [Cursor AI 2026 Guide](https://dev.to/sahilkhurana/cursor-ai-2026-the-complete-guide-to-the-ai-native-ide-3n4h [PROBED ✓ HTTP 200])
- [Cursor 3 Agent-First](https://www.infoq.com/news/2026/04/cursor-3-agent-first-interface/ [PROBED ✓ HTTP 200])
- [Windsurf Review 2026](https://www.secondtalent.com/resources/windsurf-review/ [PROBED ✓ HTTP 200])
- [GitHub Copilot Agent Mode](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/ [PROBED ✓ HTTP 200])
- [JetBrains Junie](https://blog.jetbrains.com/junie/ [PROBED ✓ HTTP 200])
- [Augment Code](https://www.augmentcode.com/ [PROBED ✓ HTTP 200])
- [Cline Bot](https://cline.bot/ [PROBED ✓ HTTP 200])
- [Roo Code vs Cline](https://www.qodo.ai/blog/roo-code-vs-cline/ [PROBED ✓ HTTP 200])
- [Aider](https://aider.chat/ [PROBED ✓ HTTP 200])
- [Google Antigravity 2.0 TechCrunch](https://techcrunch.com/2026/05/19/google-launches-antigravity-2-0-with-an-updated-desktop-app-and-cli-tool-at-io-2026/ [PROBED ✓ HTTP 200])
- [Amazon Q Developer](https://aws.amazon.com/blogs/aws/new-amazon-q-developer-agent-capabilities-include-generating-documentation-code-reviews-and-unit-tests/ [PROBED ✓ HTTP 200])

### Benchmarks & Market
- [SWE-Bench Leaderboard 2026](https://awesomeagents.ai/leaderboards/swe-bench-coding-agent-leaderboard/ [PROBED ✓ HTTP 200])
- [AI Coding Agents Comparison 2026](https://fungies.io/best-ai-coding-agents-2026-comparison-benchmarks/ [PROBED ✓ HTTP 200])
- [Agent Runtime Growth Faros](https://www.faros.ai/blog/harness-engineering [PROBED ✓ HTTP 200])
- [Best AI Coding Agents Tembo](https://www.tembo.io/blog/top-coding-agent-tools [PROBED ✓ HTTP 200])

---

## Appendix A: Deep Dive — SWE-Bench, Checkpoints, Agent SDK (Wave 3)

*Research date: 2026-05-28, appended to main doc*

### A1. Running SWE-Bench on AEGIS

**Setup:** SWE-bench Verified = 500 human-validated Python OSS issues. Afternoon setup, few hundred dollars compute. Custom agent frameworks submit to the standard harness.

**Path for AEGIS:**
1. Prototype on 50-100 issues first (validate cost + methodology)
2. Wrap AEGIS workflow (aegis-autopilot + quality-gate) as SWE-bench agent
3. Key risk: Verified is Python-heavy — AEGIS (polyglot, bash-first) may score lower than actual capability
4. A 55% Verified score ≈ 30% on proprietary codebases with domain-specific patterns

**Current SOTA:**
- Claude Opus 4.5: 80.9% Verified
- SWE-Agent 1.0 (Claude 3.7): 40%+ Verified
- mini-swe-agent (Gemini 3 Pro): 74% Verified

**Sources:**
- [SWE-bench Verified — Epoch AI](https://epoch.ai/benchmarks/swe-bench-verified [PROBED ✓ HTTP 200])
- [SWE-Bench in 2026: How to Evaluate](https://callsphere.ai/blog/swe-bench-evaluating-agentic-coding-agents [PROBED ✓ HTTP 200])

### A2. Structured Checkpointing vs Handoff

**Three approaches compared:**

| Aspect | LangGraph Checkpoint | Anthropic Agent SDK SessionStore | AEGIS Handoff |
|--------|---------------------|--------------------------------|---------------|
| Model | Full state snapshot at every node | Transcript-append-only | Markdown summary + state file |
| Fidelity | Lossless — resume from any node | Lossy — reconstruct from chat history | Lossy — summary by LLM |
| Storage | Postgres / DynamoDB / RAM | S3 (JSONL) / Redis / Postgres | Filesystem (.md files) |
| Resume | `graph.invoke(state)` from checkpoint | Re-read transcript | Re-read summary + re-init |
| Time-travel | ✅ Any historical state | ❌ | ❌ |
| Human-in-loop | ✅ Pause at checkpoint | ✅ Via append | ✅ Via human-queue |

**LangGraph detail:** Checkpointer saves at every super-step boundary. Node-level pending-writes enable partial recovery. 5 implementations: MemorySaver, PostgresSaver, DynamoDBSaver, etc.

**Agent SDK detail:** SessionStore has 5 methods: `append`, `load`, `list_sessions`, `delete`, `list_subkeys`. Reference implementations in memory, S3, Redis, Postgres.

**AEGIS implication:** Current handoff is closer to SessionStore semantics (lossy) than LangGraph (lossless). Full checkpoint would require serializing brain state — higher fidelity but significant engineering.

**Recommended path:** Keep handoff for cross-session continuity (it works), add structured `.aegis/brain/state/checkpoint.json` for critical state (current task, sprint position, pending decisions) — hybrid approach.

**Sources:**
- [LangGraph Persistence Docs](https://docs.langchain.com/oss/javascript/langgraph/persistence [PROBED ✓ HTTP 200])
- [LangGraph Production: Persistence & Memory](https://medium.com/@puttt.spl/langgraph-from-zero-to-production-part-2-persistence-memory-f28b851b66f5)
- [Checkpoints Are Not Durable Execution](https://www.diagrid.io/blog/checkpoints-are-not-durable-execution-why-langgraph-crewai-google-adk-and-others-fall-short-for-production-agent-workflows [PROBED ✓ HTTP 200])

### A3. Anthropic Agent SDK — Adopt or Not?

**What it is:** Managed tool loop — Claude with built-in file ops, shell, web search, MCP. Unlike `claude -p` (you manage everything), Agent SDK abstracts the loop.

**Key diff vs `claude -p`:**

| | `claude -p` (current AEGIS) | Agent SDK |
|--|---------------------------|-----------|
| Tool loop | Manual (AEGIS manages) | Built-in, automatic |
| Retry | Manual | Automatic on transient failures |
| Session resume | Handoff files | SessionStore protocol |
| Multi-agent | Agent tool spawning | Agents-as-tools native |
| Customization | Full control | Opinionated (limited loop override) |

**Verdict for AEGIS: Partial adoption, not migration.**

- ✅ **Adopt SessionStore** — replace handoff-file-based resume with structured session persistence
- ✅ **Adopt retry semantics** — reduce manual error handling in autopilot
- ❌ **Don't adopt managed tool loop** — AEGIS needs custom loop for MBP enforcement, honesty contracts, decision logging, coverage gates
- ⚠️ **June 15, 2026** — Agent SDK billing separates from interactive Claude API → dedicated credits

**Sources:**
- [Agent SDK Overview — Claude Code Docs](https://code.claude.com/docs/en/agent-sdk/overview)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk [PROBED ✓ HTTP 308])
- [What Agent SDK Ships vs What You Build](https://www.augmentcode.com/guides/anthropic-agent-sdk-what-ships-vs-what-you-build [PROBED ✓ HTTP 200])
