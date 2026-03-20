# AEGIS v6.0 -- Agent Team Framework

> "Context is King, Memory is Soul"

## Navigation
| File | When to Read | Priority |
|------|-------------|----------|
| CLAUDE.md | Every session | Required |
| CLAUDE_safety.md | Before git/file ops | Required |
| CLAUDE_agents.md | Before spawning agents | As needed |
| CLAUDE_skills.md | When choosing skills | As needed |
| CLAUDE_lessons.md | When stuck or deciding | Reference |

## Golden Rules
1. NEVER use --force flags on git
2. NEVER push to main -- branch + PR always
3. NEVER git commit --amend -- breaks all agents
4. NEVER end turn before agents finish (false-ready guard)
5. Run /aegis-start at session begin
6. Run /aegis-retro at session end

## Autonomy Levels
- L1: Human approves every action (default for new projects)
- L2: Human approves plans, agents execute
- L3: Agents autonomous, human reviews output
- L4: Fully autonomous with async monitoring

## Quick Commands
| Command | Purpose |
|---------|---------|
| /aegis-start | Begin session -- load brain + check context |
| /aegis-retro | End session -- retrospective + lessons |
| /aegis-pipeline | Full analysis pipeline |
| /aegis-team-build | Spawn build team (tmux) |
| /aegis-team-review | Spawn review team (tmux) |
| /aegis-status | Check all agent progress |
| /aegis-mode | Switch profile: minimal/standard/full |
