# Security Audit — AEGIS Dashboard
**Auditor:** Vigil (Security Review Pass)
**Date:** 2026-03-30
**Scope:** Next.js 15 + React 19 dashboard — all API routes, path guard, data exposure, dependencies
**Verdict:** CONDITIONAL PASS — 2 Critical, 4 High, 5 Medium findings. Criticals must be resolved before remote deployment.

---

## Summary

The dashboard is designed as a local developer tool. For that use case the risk profile is low. However, the current code contains two critical vulnerabilities that would be directly exploitable if the dashboard were exposed on a network — even an internal one. Several high-severity issues compound the blast radius. No secrets or credentials were found hardcoded. No `dangerouslySetInnerHTML` usage was found; React's default escaping prevents XSS in rendered content.

npm audit: **0 known CVEs** in installed dependencies.

---

## Findings

| # | Severity | Category | File | Finding | Fix |
|---|----------|----------|------|---------|-----|
| 1 | CRITICAL | Path Traversal | `src/app/api/specs/route.ts:59` | `..` string check is bypassable. The guard `filePath.includes("..")` fires on literal `..` but does NOT catch encoded variants: `%2e%2e%2f`, `%2e%2e/`, `..%2f`, `%252e%252e`, null-byte variants, or Unicode lookalikes. An attacker who can send a request with `?file=%2e%2e%2fetc%2fpasswd` would bypass the string check. The secondary `startsWith(specsDir)` check on the `path.resolve()` result IS correct and would stop most of these — BUT only if `specsDir` itself is resolved correctly and does not have a trailing separator issue on edge cases. The string check creates a false sense of security and should be removed entirely in favour of the resolve-then-startsWith check alone. | Remove the `includes("..")` check entirely. Rely solely on `path.resolve` + `startsWith(specsDir + path.sep)` (note: `specsDir` itself must end with `path.sep` when comparing, or use `resolved === specsDir \|\| resolved.startsWith(specsDir + path.sep)`). The current secondary check is almost right but needs the `+ path.sep` suffix to prevent a sibling directory attack (e.g., `specsDirExtra` would pass a bare `startsWith(specsDir)` check). |
| 2 | CRITICAL | Information Disclosure — Internal Filesystem Path | `src/app/api/sprints/route.ts:30` | The API response includes the **full absolute filesystem path** of each sprint directory: `path: path.join(sprintsDir, e.name)`. This exposes the server's home directory layout (e.g., `/Users/phariyawit.jiap/Documents/AEGIS-Team-1/_aegis-brain/sprints/sprint-1`) to any client that calls `/api/sprints`. If this dashboard is exposed remotely, attackers learn the exact server path, making further exploitation (LFI chaining, path guessing) significantly easier. | Return only the sprint name, not the absolute path. The `SprintInfo` type's `path` field should be removed or replaced with a relative identifier. |
| 3 | HIGH | Error Message Leaks Internal Paths | Multiple routes | All catch blocks do `error: String(err)` and return it in the JSON response. Node.js `Error` objects for filesystem operations include the full absolute path (e.g., `ENOENT: no such file or directory, open '/Users/phariyawit.jiap/...'`). This is present in: `heartbeat/route.ts:152`, `agents/route.ts:129`, `kanban/route.ts:35`, `gates/route.ts:83`, `context/route.ts:95`, `metrics/route.ts:85`, `sprints/route.ts:45`. | Sanitize error messages before returning them. In production, return a generic message like `"Internal error"` and log the real error server-side only. A simple wrapper: `const safeError = process.env.NODE_ENV === 'production' ? 'Internal error' : String(err)`. |
| 4 | HIGH | Sensitive Filesystem Path in Heartbeat API | `src/app/api/heartbeat/route.ts:49` | The hardcoded path `/private/tmp/claude-501` is probed and the `source` field in the response can reveal the string `"agent-process"` along with context that confirms the agent is active. While the path itself is not returned, its existence reveals that AI agent processes are running under UID 501 on this machine. Under remote access, this is operational intelligence. | Move the tmp path to an environment variable. Consider not leaking agent-process status strings in the API response; map internal source values to opaque codes or omit from the public response. |
| 5 | HIGH | No Authentication or Rate Limiting on Any Route | All API routes | All nine API routes are fully open with no authentication, no rate limiting, and no CSRF protection. The `next.config.ts` sets no headers. Anyone who can reach the port can read all agent state, task data, sprint metadata, and file contents within the specs directory. | Add a middleware (`src/middleware.ts`) that: (1) checks an `AEGIS_DASHBOARD_TOKEN` env var against a bearer token or cookie, and (2) restricts origins via CORS headers. For a local-only tool, at minimum bind to `127.0.0.1` in the `dev` script (`next dev --hostname 127.0.0.1 -p 4321`). |
| 6 | HIGH | `path-guard.ts` is Defined but Not Used by Any API Route | `src/lib/path-guard.ts` | The `guardPath()` utility exists and is largely correct, but **zero** of the nine API routes import or call it. All path construction in the routes uses raw `path.join(BRAIN_DIR, ...)` with no validation. If `BRAIN_DIR` were ever influenced by user input (currently it is not — it comes from `process.env.AEGIS_ROOT`), this would be exploitable. The guard is dead code providing false assurance. | Either integrate `guardPath()` into every route that constructs file paths, or document explicitly that it is only for future user-supplied paths and add a linting rule to enforce its use when `searchParams` drives filesystem reads (which currently only happens in `specs/route.ts`). |
| 7 | MEDIUM | `AEGIS_ROOT` Environment Variable Injection | `src/lib/constants.ts:5` | `AEGIS_ROOT` is read from `process.env` with no validation. If an attacker can influence the environment (e.g., via a `.env.local` file committed by mistake, or a misconfigured deployment platform), they could redirect `BRAIN_DIR` and `OUTPUT_DIR` to arbitrary paths, bypassing all path assumptions. | Validate that `AEGIS_ROOT` resolves to an expected parent of the process working directory. Add a startup assertion: `if (!AEGIS_ROOT.startsWith(expectedBase)) throw new Error(...)`. |
| 8 | MEDIUM | JSON.parse on Unvalidated File Content | `src/app/api/agents/route.ts:35`, `gates/route.ts:33`, `metrics/route.ts:22,49`, `context/route.ts:32,45` | All routes call `JSON.parse(content)` on file content without schema validation. A malformed or maliciously crafted `meta.json` (prototype pollution, deeply nested objects, huge payload) could cause unexpected behaviour. Prototype pollution via JSON is largely mitigated in V8/Node 20+, but deeply nested JSON can cause stack overflows. | Use a schema validation library (zod, or a simple structural check) to validate parsed task/metrics objects before using them. |
| 9 | MEDIUM | `activity.log` Content Rendered Directly in UI Without Sanitisation | `src/components/timeline/ActivityFeed.tsx:50`, `src/lib/parsers.ts` | Log file content is parsed and rendered as React text nodes (safe from XSS due to React's default escaping). However, the `raw` field is preserved in `ActivityLogEntry` and the `message` field contains arbitrary log text. If any future component renders these fields via `dangerouslySetInnerHTML` (e.g., to support Markdown), the unsanitised log content would be a stored XSS vector. The risk is latent, not active. | Add an explicit comment in `ActivityFeed.tsx` and `parsers.ts` marking these fields as untrusted. If Markdown rendering is ever added, use a sanitiser (DOMPurify or `sanitize-html`) before passing to an HTML renderer. |
| 10 | MEDIUM | `readdir({ recursive: true })` on `/private/tmp/claude-501` | `src/app/api/heartbeat/route.ts:53` | A recursive directory read on a world-writable `/tmp` path is a TOCTOU and resource exhaustion risk. A malicious local user could create a deep symlink tree under `/tmp/claude-501` to cause the heartbeat route to hang or consume excessive memory. | Replace the recursive readdir with a shallow read (`recursive: false`) — only the top-level `.output` files are needed. Add a max-entries guard. |
| 11 | LOW | No Security Headers Set | `next.config.ts` | The Next.js config sets no HTTP security headers: no `X-Content-Type-Options`, no `X-Frame-Options`, no `Content-Security-Policy`, no `Referrer-Policy`. A CSP would mitigate any future XSS if the no-`dangerouslySetInnerHTML` discipline slips. | Add a `headers()` function in `next.config.ts` returning standard security headers. Next.js documents this pattern. Minimum: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`. |

---

## Pass 1 — Correctness

- All routes use `force-dynamic`, correct for live filesystem reads.
- `path.resolve` + `startsWith` in `specs/route.ts` is the correct pattern. The redundant `includes("..")` check is harmless but misleading (see Finding 1).
- `JSON.parse` without try/catch at the outer level is guarded by the per-iteration try/catch in loops — adequate but not schema-safe (Finding 8).
- `parseActivityLog` and `parseKanbanMd` are pure parsers with no filesystem access — correct.
- `checkProcessAlive` in heartbeat does not expose file content, only a boolean status — acceptable.

## Pass 2 — Security

Critical issues: Findings 1, 2. Must fix before any network exposure.
High issues: Findings 3, 4, 5, 6. Fix before staging/production.
See table above for full detail.

## Pass 3 — Performance

- `readdir({ recursive: true })` on tmp (heartbeat) can be slow if the directory grows. Finding 10 covers this.
- No caching on any route — appropriate for a live monitoring tool.
- No concern with current payload sizes.

## Pass 4 — Maintainability

- `path-guard.ts` creates confusion: it exists, it looks like the security layer, but it is unused. This is the most dangerous kind of dead code — it gives reviewers and future developers false confidence. Either use it or delete it.
- Hardcoded `"sprint-1"` and date strings in `metrics/route.ts` (lines 50, 63–65) are tech debt, not security issues.
- Error handling is copy-pasted across 7 routes. Extract a `safeErrorResponse()` helper.

## Pass 5 — SDD Compliance

- `path-guard.ts` was presumably written to satisfy a security requirement in the SDD but is not wired in. This is a compliance gap.
- No rate limiting or authentication is implemented, which would be required for any deployment target beyond `localhost`.

---

## Attack Scenario: Can an attacker read `/etc/passwd` via the specs API?

**Short answer: No — but only because the secondary check saves it.**

The `includes("..")` guard would be bypassed by `%2e%2e%2f` (URL-encoded traversal). The request URL `?file=%2e%2e%2fetc%2fpasswd` would be decoded by the WHATWG URL parser to `../etc/passwd` before it reaches `searchParams.get("file")`. At that point `filePath.includes("..")` would match (because the decoded value contains `..`) — so the first check would block it in this specific case.

However, double-encoded variants like `%252e%252e%252f` (where `%25` decodes to `%`) would produce a `filePath` of `%2e%2e%2fetc%2fpasswd`, which does NOT contain `..`. `path.resolve(specsDir, "%2e%2e%2fetc%2fpasswd")` resolves to a path WITHIN `specsDir` (since `%2e` is a literal percent-encoded string to the filesystem, not a traversal). The secondary `startsWith(specsDir)` check would PASS, but the file `specsDir/%2e%2e%2fetc/passwd` would not exist, so `fs.readFile` would throw ENOENT. Net result: **no file read**, but only due to filesystem mechanics, not intentional security logic.

The correct mitigation remains: remove the `includes("..")` string check, keep and harden the `resolve + startsWith` check, and ensure `specsDir` ends with `path.sep` in the comparison.

---

## Recommended Fix Priority

1. **Immediate (before any network exposure):** Finding 2 (path leak in sprints API), Finding 3 (error message leaks)
2. **Before staging:** Finding 5 (add auth/bind to localhost), Finding 1 (harden path guard in specs)
3. **This sprint:** Finding 6 (wire up or remove path-guard.ts), Finding 4 (harden heartbeat source disclosure)
4. **Next sprint:** Findings 7–11

---

## Dependency Audit

`npm audit` in `/dashboard`: **0 vulnerabilities found.**
Dependencies: next@15.1.x, react@19.x, swr@2.2.x — all current, no known CVEs.

---

_Report generated by Vigil — do not modify findings without re-running the review pass._
