# AEGIS External Adoption Guide

> **Purpose**: apply AEGIS to a project that isn't this meta-repo. Closes
> dogfood observation #4 — every AEGIS session so far has been
> AEGIS-improving-AEGIS; a real external app will surface failure modes
> the meta-repo can't.

## Minimum viable adoption

To get AEGIS running in an existing project with minimal footprint:

```
<target-repo>/
├── .aegis/
│   └── brain/                    # created by install, gitignored selectively
│       ├── resonance/            # auto-populated on /aegis-start
│       ├── instincts/
│       ├── learnings/
│       ├── retrospectives/
│       ├── handoffs/
│       ├── sprints/
│       ├── logs/                 # gitignored
│       └── MEMORY.md             # auto-generated index
├── .claude/
│   ├── agents/*.md               # the 10 active agents
│   ├── commands/*.md             # slash commands
│   ├── hooks/*.sh                # guard-bash, guard-write, session-start,
│   │                               post-tool-use, on-stop
│   ├── references/*.md           # protocols + specs
│   ├── settings.json             # hardened permission model
│   └── teams/*.md                # team configs
├── tools/aegis-*.sh              # helper scripts
├── CLAUDE.md                     # project-specific instructions
├── AEGIS_VERSION                 # version pinning
└── .gitignore                    # AEGIS block (sentinel-marked)
```

Target footprint: ~2MB on disk, <50 files.

## Quick install (meta-repo layout as donor)

```bash
# In the target project's root:
export TARGET=$(pwd)
export META=/path/to/AEGIS-Team    # this meta-repo

# 1. Copy framework files
cp -R "$META/.claude" "$TARGET/.claude"
cp -R "$META/tools" "$TARGET/tools"
mkdir -p "$TARGET/.aegis/brain/"{resonance,instincts/{promoted,active,pending},learnings/raw,retrospectives,handoffs,sprints,logs,state}

# 2. Copy version + gitignore block
cp "$META/VERSION" "$TARGET/AEGIS_VERSION" 2>/dev/null || echo "9.0" > "$TARGET/AEGIS_VERSION"

# 3. Append AEGIS gitignore block (sentinel-marked for updates)
cat "$META/.gitignore" | sed -n '/<<< AEGIS-V9-START >>>/,/<<< AEGIS-V9-END >>>/p' >> "$TARGET/.gitignore"

# 4. Make tools executable
chmod +x "$TARGET/tools/aegis-"*.sh "$TARGET/.claude/hooks/"*.sh

# 5. Verify
cd "$TARGET" && ./tools/aegis-brain-sync.sh --validate
```

This is the manual form. The future plugin flow (Stream 3 in the
ecosystem guide) automates this via `npx aegis install`.

## Project-specific CLAUDE.md

After copying framework files, create a `CLAUDE.md` at the target root
that describes *this* project, not AEGIS. Template:

```markdown
# <Project Name> -- Agent Framework

> Your project's one-line mission.

## Navigation
| File | When to Read | Priority |
|------|-------------|----------|
| CLAUDE.md | Every session | Required |

## Golden Rules
1. NEVER use --force flags on git
2. NEVER push to main -- branch + PR always
3. NEVER git commit --amend -- breaks all agents
4. Run /aegis-start at session begin
5. Run /aegis-retro at session end

## Project Context
- Stack: <e.g., Next.js + Postgres>
- Owner: <team>
- Prod URL: <url>
- Core invariants: <what must never break>

## Quick Commands
(inherit from AEGIS)
```

Keep it under 60 lines. The brain's `resonance/project-identity.md` holds
the rich project context; CLAUDE.md is just the nav + golden rules.

## First `/aegis-start` in the target repo

On first run, Nick Fury will detect an empty brain and activate P10
(empty project) flow:

```
🧬 Nick Fury: Brain is empty.
   One question: what is this project? One sentence is enough.
```

Answer with the project's mission in one sentence. Nick Fury writes the
answer to `.aegis/brain/resonance/project-identity.md` and proceeds
autonomously from there.

## What surfaces that meta-repo can't

Running AEGIS on a real external app will expose failure modes the
meta-repo dogfood hides:

1. **Non-bash stacks**. The meta-repo is mostly bash/markdown. A real
   Node/Python/Go repo will stress the tool-matrix assumptions and reveal
   which AEGIS hooks/tools are silently bash-only.

2. **Real CI/CD pressure**. The meta-repo has no CI. A real repo's GitHub
   Actions/GitLab CI will either tolerate AEGIS or fight it. Guard-bash
   and guard-write need to behave correctly in non-interactive contexts.

3. **Real collaborator friction**. When someone who didn't install AEGIS
   joins the repo, do they understand what `.claude/` is? What does the
   brain look like to them in a PR review?

4. **Real sprint cadence**. The meta-repo's sprints are contrived (they
   produce AEGIS itself). A real sprint with customer-facing deadlines
   will stress-test Nick Fury's decision matrix under actual time pressure.

5. **Real data / migration pain**. Brain state, kanban, ADRs all need to
   survive rebases, resets, branch renames. The meta-repo rarely exercises
   these; an active team repo does it weekly.

## Recommended first target

Pick a project where:
- You have unilateral commit rights (so AEGIS adoption is a choice, not
  a debate with teammates).
- The stack is NOT markdown+bash (forces AEGIS out of its comfort zone).
- There's at least one active backlog item waiting for implementation
  (so AEGIS has real work to do on arrival).
- You can tolerate ~30 min of friction during first `/aegis-start` (brain
  seeding + BLOCK 0 document generation).

A low-stakes personal side-project or a greenfield internal tool is
ideal. Avoid: production-critical services, regulated codebases, or
repos with strict commit-policy CI that might reject AEGIS commits
(guard-bash warns on push-to-main which fails some policies).

## Reporting adoption findings

Every external adoption should produce at least one
`.aegis/brain/learnings/<date>_<slug>.md` describing what surprised the
adopter. PR those learnings back here (into the meta-repo's
`learnings/` dir) so the framework evolves from field data.

Suggested slug prefixes:
- `ext-` for external-adoption-specific findings (`ext-nodejs-hook-gap.md`)
- Generic slugs for findings that apply to any AEGIS project

## TL;DR

```
1. Copy .claude/ + tools/ + .aegis/brain/ scaffolding to target repo
2. Add AEGIS gitignore block + AEGIS_VERSION file
3. Write a minimal CLAUDE.md for the target project
4. Run /aegis-start — answer Nick Fury's one identity question
5. Let Nick Fury drive for 1-2 sprints
6. File learnings back to the meta-repo as PRs
```

That's it. AEGIS is designed to carry its own setup cost in the first
session; everything after that is workflow.
