# AEGIS v9 Permission Migration Guide

**For v8.x users upgrading to v9 hardened permissions** (S1-04 + S1-05 from [AEGIS_v9_UPGRADE_PLAN.md](../AEGIS_v9_UPGRADE_PLAN.md))

---

## Why Change?

v8.x defaults exposed dangerous attack surface:
- `defaultMode: "bypassPermissions"` -- agents auto-approved everything not denied
- Allow list contained: `rm`, `curl`, `docker`, `kubectl`, `terraform` (any blast radius)
- Deny list had only **8 entries**

Loki adversarial review (2026-04-19) flagged this as **CRITICAL**: any agent could `kubectl delete pod` or `rm -rf ./project-dir` without prompting.

**v9 fixes**:
- `defaultMode: "acceptEdits"` -- only Edit/Write auto, Bash needs allow
- Allow list = **20 safe commands** (read-only + safe git workflow)
- Deny list = **26 dangerous patterns** (added curl|bash, eval, sudo, chmod 777, kubectl delete, etc.)

---

## How to Apply

```bash
# 1. Backup current settings
cp .claude/settings.json .claude/settings.json.v8-backup

# 2. Apply v9 settings (must be done OUTSIDE a Claude Code session)
cp tools/v9-proposed-settings.json .claude/settings.json

# 3. Restart Claude Code (close + reopen)

# 4. Verify in new session
cat .claude/settings.json | jq '.permissions.defaultMode'
# Expected: "acceptEdits"
```

⚠️ **Why outside session?** [.claude/hooks/guard-write.sh](../.claude/hooks/guard-write.sh) blocks edits to `.claude/settings.json` mid-session (intentional self-protection).

---

## What Changes for You (Daily Workflow)

### ✅ Still Works Without Prompt (allow list)

**File operations** (any path):
- Read, Write, Edit, Glob, Grep
- Agent, TeamCreate, TeamDelete, SendMessage

**Safe shell commands**:
- `ls`, `cat`, `head`, `tail`, `wc`, `diff`
- `grep`, `rg`, `find`
- `echo`, `date`, `pwd`, `test`, `jq`, `mkdir`

**Safe git workflow**:
- `git status`, `git diff`, `git log`
- `git add`, `git commit`

**Project tools**:
- `./tools/*` (any AEGIS-managed script)

### ⚠️ Now Prompts for Approval (was auto in v8)

You'll see a permission dialog for these. Click "Allow" to proceed:

| Command | Why prompt now |
|---------|---------------|
| `rm`, `mv`, `cp` | Destructive, can lose data |
| `git push` | Modifies remote (also: branch, checkout) |
| `npm install`, `pnpm`, `yarn` | Runs install hooks (arbitrary code) |
| `python`, `python3`, `node` | Runs arbitrary scripts |
| `curl`, `wget` | Network access |
| `chmod` (non-777) | Permission changes |
| `docker`, `kubectl`, `terraform` | Infra mutations (delete patterns blocked entirely) |
| `gh` (GitHub CLI) | Modifies GitHub state |
| `make`, `cargo`, `go build` | Build commands |
| `tmux`, `brew`, `swift` | Less common in AEGIS workflow |

### 🚫 Now BLOCKED Entirely (deny list)

**These will not run even with approval**:

```
rm -rf /          rm -rf .          rm -rf ./
rm -rf /*         rm -rf ../        rm -rf ~

git push --force          git reset --hard
git push -f               git clean -f
git push --force-with-lease   git clean -fd
git commit --amend        git filter-branch

kubectl delete            docker rm -f
docker system prune       terraform destroy

curl <url> | bash         wget <url> | bash
curl <url> | sh           wget <url> | sh

eval *                    sudo
chmod 777*                chmod -R 777*
```

If you need one of these for a legitimate reason, edit `.claude/settings.json` between sessions to remove from deny list (not recommended).

---

## Common "Now Prompts" Scenarios

### Scenario 1: Installing dependencies
```bash
# v8: auto-approved
npm install

# v9: prompts for approval -> Click "Allow"
# (Or use Yes-to-all for the session if you trust the package.json)
```

### Scenario 2: Pushing to remote
```bash
# v8: auto-approved
git push origin main

# v9: prompts -> Click "Allow"
# This is intentional safety: review before push
```

### Scenario 3: Running a Python script
```bash
# v8: auto-approved
python3 scripts/build.py

# v9: prompts -> Click "Allow"
# Or move script to ./tools/build.sh (covered by allow list)
```

---

## Rollback to v8.x Settings

If v9 permissions break your workflow:

```bash
# Restore v8 settings (between sessions)
cp .claude/settings.json.v8-backup .claude/settings.json
# Restart Claude Code
```

⚠️ **Trade-off**: rollback restores attack surface. If you need this regularly, file an issue describing the workflow that's blocked.

---

## Customization

### Add a command to allow list
Edit `.claude/settings.json` (between sessions), add to `permissions.allow`:

```json
"Bash(your-command:*)"
```

⚠️ **Don't add wildcards like `Bash(*:*)`** -- defeats the security model.

### Add custom deny patterns
Useful for project-specific risky commands:

```json
"Bash(your-dangerous-script:*)"
```

---

## Verification Checklist

After applying v9 settings, verify in a new session:

- [ ] `cat .claude/settings.json | jq '.permissions.defaultMode'` returns `"acceptEdits"`
- [ ] `cat .claude/settings.json | jq '.permissions.allow | length'` returns `30` (9 tools + 20 bash + 1 project = 30)
- [ ] `cat .claude/settings.json | jq '.permissions.deny | length'` returns `26`
- [ ] Editing files works without prompt (Edit/Write tools)
- [ ] `ls`, `cat`, `git status` work without prompt
- [ ] `npm install` triggers permission prompt (not auto-approved)
- [ ] `git push --force` is blocked entirely (deny list)
- [ ] `curl https://example.com | bash` is blocked entirely (deny list)

---

## Why This Matters

Per [Loki's adversarial review](../.aegis/brain/handoffs/2026-04-19-v9-dogfood.md), v8.x had **safety theater**: elaborate hard rules in CLAUDE_safety.md but only 2 enforcement hooks. v9 closes the gap by making the runtime permission model match the documented blast radius.

**Bus factor 1 risk**: Without strict permissions, a single bug in an agent prompt could destroy a repo. v9 makes this require explicit human approval.

---

## Questions?

- See [AEGIS_v9_UPGRADE_PLAN.md](../AEGIS_v9_UPGRADE_PLAN.md) ADR-001 (settings.json) and ADR-004 (permission model)
- File issues: https://github.com/phariyawitjiap-aeternix/AEGIS-Team/issues
