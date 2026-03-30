---
name: aegis-devops
description: "DevOps team: build verification, deployment, health checks, monitoring, rollback"
lead: ops
members: [bolt]
mode: in-process
requires: agent-teams
---

## Team Purpose
Infrastructure pipeline: Ops builds release artifacts, deploys, runs health checks,
monitors post-deploy stability, and coordinates with Bolt for hotfixes if needed.

## Input Contract

```json
{
  "team": "devops",
  "trigger": "release approved (all gates PASS) OR hotfix request",
  "required_inputs": {
    "release_scope": "list of task IDs included in release",
    "gate_results": {
      "gate_1": "PASS for all tasks",
      "gate_2": "PASS for all tasks >= 3pts",
      "gate_3": "PASS (ISO docs current)"
    },
    "deploy_config": "deploy/config.yaml",
    "health_checks": "deploy/health-checks.yaml"
  }
}
```

## Task Breakdown

### 1. Ops (sonnet): Pre-deploy build verification
- Reads: Project source, build configuration
- Executes: Clean build from branch HEAD
- Produces: `_aegis-output/deploys/build-{timestamp}.log`
- Validation: Build artifacts exist, size is non-zero, checksums recorded

### 2. Ops (sonnet): Deploy to target environment
- Reads: Build artifacts, deploy/config.yaml
- Executes: Deploy command sequence per configured strategy (rolling/blue-green/canary)
- Produces: `_aegis-output/deploys/deploy-{timestamp}.log`

### 3. Ops (sonnet): Health check (within 60 seconds)
- HTTP endpoint check (configurable URL, expected status, timeout)
- Process check (expected processes running)
- Log check (no FATAL/PANIC in last 60s of logs)
- Custom checks (defined in deploy/health-checks.yaml)

### 4. Ops (sonnet): Monitor (5 minutes post-deploy)
- Watch error rate against baseline
- If error_rate > 2x baseline: auto-rollback
- If error_rate > 1.5x baseline: WARNING alert, continue monitoring
- Produces: `_aegis-output/deploys/monitor-{timestamp}.log`

### 5. Bolt (sonnet): Hotfix (only on failure)
- Activated when Ops detects unhealthy deploy or error spike
- Reads: Ops error report, relevant source code
- Produces: Hotfix code change
- Ops redeploys after Bolt's fix

## Communication Flow
Ops -> build log -> Ops (deploy)
Ops -> deploy status -> Ops (health check)
Ops -> health result -> monitor OR rollback
Ops -> EscalationAlert (on failure) -> Navi + Bolt
Bolt -> hotfix code -> Ops (redeploy)

## Output Contract

```json
{
  "from_team": "devops",
  "task_id": "release-vX.Y.Z",
  "status": "DEPLOYED_HEALTHY OR ROLLED_BACK OR CRITICAL_FAILURE",
  "artifacts": {
    "build_log": "_aegis-output/deploys/build-{timestamp}.log",
    "deploy_log": "_aegis-output/deploys/deploy-{timestamp}.log",
    "health_report": "_aegis-output/deploys/health-{timestamp}.log",
    "monitor_report": "_aegis-output/deploys/monitor-{timestamp}.log"
  },
  "gate_results": {
    "gate_4": "PASS or FAIL (deploy + health)",
    "gate_5": "PASS or FAIL (5 min monitor)"
  }
}
```

## Handoff Rules
- **healthy** -> monitor phase (5 min) -> STABLE (pipeline complete)
- **unhealthy** -> rollback to previous version + create hotfix task via PM.03

## Rollback Protocol
1. Revert to previous known-good deployment
2. Re-run health checks to confirm rollback success
3. If rollback also fails: CRITICAL alert to Navi + human
4. Scribe generates PM.03 Correction Register entry
5. Navi creates hotfix task in backlog with CRITICAL priority

## ISO Triggers
- **SI.07** (Software Configuration): Scribe updates with deployment record
- **PM.03** (Correction Register): Scribe generates on any deploy failure or rollback

## Output
_aegis-output/deploys/
