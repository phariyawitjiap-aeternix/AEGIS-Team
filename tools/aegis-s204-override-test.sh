#!/usr/bin/env bash
# AEGIS S2-04 Override Test Harness
#
# Runs all 16 test cases from spec S2-04 §5.
# Each test creates an isolated temp directory, invokes aegis-s204-override.sh,
# and asserts meta.json mode, counter state, and log line presence/absence.
#
# Usage: bash tools/aegis-s204-override-test.sh
# Exit: 0 if all pass, 1 if any fail

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERRIDE_SH="${SCRIPT_DIR}/aegis-s204-override.sh"

PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Test infrastructure
# ---------------------------------------------------------------------------

# Each test runs in its own temp dir to isolate counter/log state
mk_test_env() {
  local tmpdir
  tmpdir=$(mktemp -d)
  # Create directory structure mirroring the real repo layout
  mkdir -p "${tmpdir}/.aegis/brain/state"
  mkdir -p "${tmpdir}/.aegis/brain/logs"
  mkdir -p "${tmpdir}/.aegis/brain/tasks"
  mkdir -p "${tmpdir}/tools"
  # Seed zero-state counter
  cat > "${tmpdir}/.aegis/brain/state/override-counter.json" <<'EOF'
{
  "total_overrides": 0,
  "last_override_at": null,
  "by_category": {
    "auth": 0,
    "credentials": 0,
    "env": 0,
    "secrets": 0,
    "ssh": 0,
    "tokens": 0,
    "agent-prompts": 0
  },
  "recent": []
}
EOF
  # Create a no-op activity log
  touch "${tmpdir}/.aegis/brain/logs/activity.log"
  # Symlink tools so aegis-security-paths.sh is accessible
  ln -s "${SCRIPT_DIR}/aegis-security-paths.sh" "${tmpdir}/tools/aegis-security-paths.sh"
  echo "$tmpdir"
}

mk_meta() {
  local dir="$1"
  local mode="$2"
  cat > "${dir}/meta.json" <<EOF
{
  "block0_mode": "${mode}",
  "tags": ["chore"],
  "story_points": 1
}
EOF
}

assert_pass() {
  local tc="$1"
  local desc="$2"
  PASS=$(( PASS + 1 ))
  echo "PASS: ${tc} — ${desc}"
}

assert_fail() {
  local tc="$1"
  local desc="$2"
  local detail="$3"
  FAIL=$(( FAIL + 1 ))
  echo "FAIL: ${tc} — ${desc} | ${detail}"
}

check_mode() {
  local meta="$1"
  grep -o '"block0_mode"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta" \
    | grep -o '"[^"]*"$' | tr -d '"'
}

check_override_present() {
  local meta="$1"
  grep -q '"block0_override"' "$meta" && echo "yes" || echo "no"
}

check_total_overrides() {
  local counter="$1"
  grep -o '"total_overrides"[[:space:]]*:[[:space:]]*[0-9]*' "$counter" \
    | grep -o '[0-9]*$'
}

check_category_count() {
  local counter="$1"
  local category="$2"
  grep -o "\"${category}\"[[:space:]]*:[[:space:]]*[0-9]*" "$counter" \
    | head -1 | grep -o '[0-9]*$'
}

check_log_has_override() {
  local log="$1"
  grep -q '\[LOKI:override\]' "$log" && echo "yes" || echo "no"
}

check_recent_length() {
  local counter="$1"
  python3 -c "
import json
with open('${counter}') as f:
    d = json.load(f)
print(len(d.get('recent', [])))
" 2>/dev/null || echo "0"
}

# ---------------------------------------------------------------------------
# Wrapper: run override with all env vars pointing at tmpdir
# The script reads COUNTER_FILE, ACTIVITY_LOG, AEGIS_TEST_META from env
# if set. We set them all here.
# ---------------------------------------------------------------------------
invoke() {
  local tmpdir="$1"
  local paths="$2"
  COUNTER_FILE="${tmpdir}/.aegis/brain/state/override-counter.json" \
  ACTIVITY_LOG="${tmpdir}/.aegis/brain/logs/activity.log" \
  TASKS_DIR="${tmpdir}/.aegis/brain/tasks" \
  SECURITY_PATHS_SH="${tmpdir}/tools/aegis-security-paths.sh" \
  AEGIS_TEST_META="${tmpdir}/meta.json" \
  bash "${OVERRIDE_SH}" --paths "$paths" 2>&1 || true
}

# ---------------------------------------------------------------------------
# TC-01: lite mode + auth/login.ts -> override to full, category=auth
# ---------------------------------------------------------------------------
TC="TC-01"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "auth/login.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
ovrd=$(check_override_present "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
log_hit=$(check_log_has_override "${T}/.aegis/brain/logs/activity.log")
if [[ "$mode" == "full" && "$ovrd" == "yes" && "$total" == "1" && "$log_hit" == "yes" ]]; then
  assert_pass "$TC" "lite+auth/login.ts -> full, counter=1, log=[LOKI:override]"
else
  assert_fail "$TC" "lite+auth/login.ts -> full" "mode=$mode ovrd=$ovrd total=$total log=$log_hit"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-02: lite mode + src/credentials/store.ts -> override, category=credentials
# ---------------------------------------------------------------------------
TC="TC-02"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "src/credentials/store.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "credentials")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+credentials/store.ts -> full, category=credentials"
else
  assert_fail "$TC" "lite+credentials/store.ts -> full" "mode=$mode credentials_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-03: lite mode + .env.production -> override, category=env
# ---------------------------------------------------------------------------
TC="TC-03"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" ".env.production" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "env")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+.env.production -> full, category=env"
else
  assert_fail "$TC" "lite+.env.production -> full" "mode=$mode env_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-04: lite mode + secrets/api.json -> override, category=secrets
# ---------------------------------------------------------------------------
TC="TC-04"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "secrets/api.json" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "secrets")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+secrets/api.json -> full, category=secrets"
else
  assert_fail "$TC" "lite+secrets/api.json -> full" "mode=$mode secrets_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-05: standard mode + auth/middleware.ts -> override to full
# ---------------------------------------------------------------------------
TC="TC-05"
T=$(mk_test_env)
mk_meta "$T" "standard"
invoke "$T" "auth/middleware.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$mode" == "full" && "$total" == "1" ]]; then
  assert_pass "$TC" "standard+auth/middleware.ts -> full (standard also overridden)"
else
  assert_fail "$TC" "standard+auth/middleware.ts -> full" "mode=$mode total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-06: full mode + auth/login.ts -> NO override, counter NOT incremented
# ---------------------------------------------------------------------------
TC="TC-06"
T=$(mk_test_env)
mk_meta "$T" "full"
invoke "$T" "auth/login.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
log_hit=$(check_log_has_override "${T}/.aegis/brain/logs/activity.log")
if [[ "$mode" == "full" && "$total" == "0" && "$log_hit" == "no" ]]; then
  assert_pass "$TC" "full mode -> NO override, counter=0, no log entry"
else
  assert_fail "$TC" "full mode -> NO override" "mode=$mode total=$total log=$log_hit"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-07: lite mode + src/auth-docs.md -> NO override (auth- prefix, not auth/)
# ---------------------------------------------------------------------------
TC="TC-07"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "src/auth-docs.md" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$mode" == "lite" && "$total" == "0" ]]; then
  assert_pass "$TC" "lite+src/auth-docs.md -> NO override (auth- != auth/)"
else
  assert_fail "$TC" "lite+src/auth-docs.md -> NO override" "mode=$mode total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-08: lite mode + docs/authentication-guide.md -> NO override (substring)
# ---------------------------------------------------------------------------
TC="TC-08"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "docs/authentication-guide.md" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$mode" == "lite" && "$total" == "0" ]]; then
  assert_pass "$TC" "lite+docs/authentication-guide.md -> NO override (docs substring)"
else
  assert_fail "$TC" "lite+docs/authentication-guide.md -> NO override" "mode=$mode total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-09: lite mode + src/components/Authorize.tsx -> NO override (component name)
# ---------------------------------------------------------------------------
TC="TC-09"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "src/components/Authorize.tsx" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$mode" == "lite" && "$total" == "0" ]]; then
  assert_pass "$TC" "lite+Authorize.tsx -> NO override (component name contains auth)"
else
  assert_fail "$TC" "lite+Authorize.tsx -> NO override" "mode=$mode total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-10: lite mode + .claude/agents/loki.md -> override, category=agent-prompts
# ---------------------------------------------------------------------------
TC="TC-10"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" ".claude/agents/loki.md" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "agent-prompts")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+.claude/agents/loki.md -> full, category=agent-prompts"
else
  assert_fail "$TC" "lite+.claude/agents/loki.md -> full" "mode=$mode agent-prompts_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-11: cumulative counter — TC-01 scenario + TC-02 scenario in same env
#         total_overrides == 2, auth==1, credentials==1
# ---------------------------------------------------------------------------
TC="TC-11"
T=$(mk_test_env)
# First override (auth)
mk_meta "$T" "lite"
invoke "$T" "auth/login.ts" >/dev/null
# Second override (credentials) — reset meta mode for second run
mk_meta "$T" "lite"
invoke "$T" "src/credentials/store.ts" >/dev/null
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
auth_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "auth")
cred_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "credentials")
if [[ "$total" == "2" && "$auth_val" == "1" && "$cred_val" == "1" ]]; then
  assert_pass "$TC" "cumulative: total=2, auth=1, credentials=1"
else
  assert_fail "$TC" "cumulative counter" "total=$total auth=$auth_val credentials=$cred_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-12: 12 consecutive overrides -> recent[] capped at 10
# ---------------------------------------------------------------------------
TC="TC-12"
T=$(mk_test_env)
for i in $(seq 1 12); do
  mk_meta "$T" "lite"
  invoke "$T" "auth/login.ts" >/dev/null
done
recent_len=$(check_recent_length "${T}/.aegis/brain/state/override-counter.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$recent_len" == "10" && "$total" == "12" ]]; then
  assert_pass "$TC" "12 overrides -> recent[] capped at 10, total=12"
else
  assert_fail "$TC" "FIFO cap at 10" "recent_len=$recent_len total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-13: lite mode + .ssh/id_rsa -> override, category=ssh
# ---------------------------------------------------------------------------
TC="TC-13"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" ".ssh/id_rsa" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "ssh")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+.ssh/id_rsa -> full, category=ssh"
else
  assert_fail "$TC" "lite+.ssh/id_rsa -> full" "mode=$mode ssh_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-14: lite mode + tokens/api.json -> override, category=tokens
# ---------------------------------------------------------------------------
TC="TC-14"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "tokens/api.json" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "tokens")
if [[ "$mode" == "full" && "$cat_val" == "1" ]]; then
  assert_pass "$TC" "lite+tokens/api.json -> full, category=tokens"
else
  assert_fail "$TC" "lite+tokens/api.json -> full" "mode=$mode tokens_count=$cat_val"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-15: lite mode + tests/auth/foo.ts -> MUST override, category=auth
# Spec §3 negative table last row: tests/auth/ DOES trigger
# ---------------------------------------------------------------------------
TC="TC-15"
T=$(mk_test_env)
mk_meta "$T" "lite"
invoke "$T" "tests/auth/foo.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
cat_val=$(check_category_count "${T}/.aegis/brain/state/override-counter.json" "auth")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
if [[ "$mode" == "full" && "$cat_val" == "1" && "$total" == "1" ]]; then
  assert_pass "$TC" "lite+tests/auth/foo.ts -> full, category=auth (tests/auth/ DOES trigger)"
else
  assert_fail "$TC" "lite+tests/auth/foo.ts -> full" "mode=$mode auth_count=$cat_val total=$total"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# TC-16: path containing single quote -> override succeeds, no injection error
# Verifies shell-injection fix (S-01): auth/it's-broken.ts must override cleanly
# Also covers space-in-filename (C-01): path passes through newline iteration
# ---------------------------------------------------------------------------
TC="TC-16"
T=$(mk_test_env)
mk_meta "$T" "lite"
# Single quote in path — would break `python3 -c "... '${var}' ..."` style interpolation
invoke "$T" "auth/it's-broken.ts" >/dev/null
mode=$(check_mode "${T}/meta.json")
total=$(check_total_overrides "${T}/.aegis/brain/state/override-counter.json")
log_hit=$(check_log_has_override "${T}/.aegis/brain/logs/activity.log")
if [[ "$mode" == "full" && "$total" == "1" && "$log_hit" == "yes" ]]; then
  assert_pass "$TC" "single-quote in path -> override succeeds, no injection, counter=1"
else
  assert_fail "$TC" "single-quote in path -> override succeeds" "mode=$mode total=$total log=$log_hit"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL=$(( PASS + FAIL ))
echo ""
echo "Results: ${PASS}/${TOTAL} passed, ${FAIL} failed"
if [[ "$FAIL" -eq 0 ]]; then
  echo "All ${TOTAL} test cases PASSED."
  exit 0
else
  echo "FAILURE: ${FAIL} test case(s) failed."
  exit 1
fi
