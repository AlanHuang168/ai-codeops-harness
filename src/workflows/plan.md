# PLAN Workflow

## Purpose

Turn a clear PRD and an Accepted ADR
into low-ambiguity, executable, verifiable implementation tasks.

PLAN answers:

- What to change
- Where to change it
- In what order to change it
- How to validate each step
- Whether any Task contains an explicit Human Decision（显式人工决策）

PLAN does not redefine requirements or architecture.
Approved PLAN（已批准计划） is the Runtime Authorization Boundary（运行授权边界）.
Approval Record（审批记录） is the machine-readable Runtime Fact that records the
Human Decision authorizing the PLAN. PLAN status alone is not sufficient for
reliable cross-session recovery unless a legacy migration record is created.

## Preconditions

Before entering PLAN, confirm:

- Requirements are clear
- Necessary business rules are confirmed
- Related ADRs are Accepted
- Data Owner is clear
- System boundaries are clear
- No blocking key decisions remain

If a requirement problem is found:

→ Return to PRD

If an architecture problem is found:

→ Return to ADR

Do not add major decisions on your own in PLAN.

## Process

### 1. Load Context

Load only what the current implementation needs:

- Related PRD
- Related ADR
- Project Context
- AGENTS.md
- Target subsystem rules
- Related code
- Schema
- Contract

> Project Context（项目上下文）resolves from the `project_context` reference in Runtime State; see the Project Context Resolution rule in `AGENTS.md`. Read it on demand only.

Select as needed:

- Role
- Rule
- Skill

Do not load all of `.ai/` by default.

### 2. Verify Reality

Before implementing, confirm:

- The ADR still matches the current code
- Files and modules actually exist
- Schema matches the plan's assumptions
- API / Contract has not drifted
- The Git working tree has no user changes needing protection

On significant Architecture Drift:

→ Stop PLAN
→ Return to ADR

### 3. Determine Change Set

Clarify:

- Modified files
- New files
- Schema / Migration
- API / Contract
- Tests
- Documentation

Do not expand into unrelated modules.

### 4. Dependency Order

Order tasks by real dependencies.

Typical order:

Schema / Contract
→ Domain
→ Repository
→ Service
→ API / Adapter
→ UI
→ Tests
→ Documentation

Adjust to the project's reality;
do not apply mechanically.

### 5. Atomic Tasks

Break the implementation into atomic tasks.

Each Task must include:

- Goal
- Target
- Dependencies
- Changes
- Validation

Tasks should be small enough
that the Agent can validate immediately after completing one.

### 6. Validation Plan

Define validation for each task:

- Type Check
- Unit Test
- Integration Test
- Build
- Manual Verification
- Failure Path
- Security Check

Do not claim that validation you cannot run has been done.

### 7. Risk Check

Before implementing, re-check:

- Data Consistency
- Compatibility
- Security
- Migration
- External Dependency
- Rollback

Stop before entering IMPL when a blocking problem is found.

## PLAN Output

At minimum:

1. Goal
2. Preconditions
3. Selected Context
4. Change Set
5. Ordered Tasks
6. Validation Plan
7. Risks
8. Documentation Impact
9. Execution Mode（执行模式） and Approval Scope（批准范围）
10. Approval Record target（审批记录目标）
11. Risk Tier（风险分级） and its selecting trigger
12. Acceptance Contract（验收契约）: technical + business
13. Eval Plan（评估计划） when the change is effect-bearing, else `N/A`
14. Release DoD flag（发布完成定义标记） when the project is deployable, else `N/A`

Risk Tier（风险分级） comes from `risk-router.md`: `fast`, `standard`, or
`architecture`. When `risk_tier` is absent, Runtime treats the PLAN as
`standard`. Record it on the PLAN and Approval Record:

```yaml
risk_tier: standard   # fast | standard | architecture
```

### Acceptance Contract（验收契约）

Every PLAN must state Technical Acceptance（技术验收） and Business Acceptance
（业务验收）. IMPL verifies this contract before Review passes.

```yaml
acceptance:
  technical:
    - tests pass
    - api compatible
  business:
    - expected fixture outputs match
    - latency target satisfied
```

- Technical items are TEST-level (code, interface, exception, contract).
- Business items are EVAL-level (effect / output quality); see `eval.md`.
- If the change is not effect-bearing, the business section may be `N/A` with a
  one-line reason.

### Eval Plan（评估计划）

For parser / algorithm / AI / rule-engine / recommendation changes, define the
Eval Contract per `eval.md`. The project owns metrics, datasets, and targets;
the PLAN records which apply:

```yaml
eval:
  - metric: <project-defined>
    dataset: <path>
    target: <threshold>
    measurement: <how measured>
```

If no effect metric applies, record `eval: N/A`.

Default:

```yaml
execution_mode: plan_continuous
approval_record:
  artifact:
    type: PLAN
    id: <PLAN-id>
  default_scope:
    allow:
      - plan_execution
      - implementation
      - validation
      - checkpoint_update
      - state_update
      - in_scope_bug_fix
      - documentation_sync
    deny:
      - destructive_operation
      - production_deploy
      - public_release
      - registry_publish
      - scope_expansion
```

`task_gated` may be used only as an explicit compatibility mode. Do not make it
the default.

## Bug-fix PLAN（缺陷修复计划）

When a PLAN Task is a bug fix, it must carry the Root Cause Gate（根因门禁）
inputs so IMPL can verify them before a high-impact change (see `impl.md`):

```yaml
root_cause:
  symptom: <observed defect>
  root_cause: <why it happens>
  why_tests_missed: <why existing tests did not catch it>
  fix_strategy: <how it is fixed>
  regression_protection: <regression case / fixture that now covers it>
```

A high-impact bug fix must not be planned without a stated root cause.

## Task Template

### Task N: <name>

Goal:
<what this task accomplishes>

Target:
<modules or files involved>

Dependencies:
<prerequisite tasks, or None>

Changes:
- <change>

Validation:
- <validation method>

Acceptance:
- technical: <technical acceptance item>
- business: <business acceptance item, or N/A>

Human Gate:
- requires_human_decision: false
- reason: null

## Forbidden

In the PLAN stage:

- Modifying business code
- Modifying Schema
- Creating a Migration
- Installing dependencies
- Redefining the PRD
- Changing an Accepted ADR on your own
- Incidental refactoring
- Expanding Scope
- Treating speculation as current state
- Basing the plan on a nonexistent file or API

## Fallback Rules

Missing business definition found:

PLAN → PRD

Missing or invalidated architecture decision found:

PLAN → ADR

Current implementation clearly inconsistent with the ADR:

PLAN → ADR

Only implementation-level detail unclear:

Resolve within PLAN.

## Completion

When PLAN is done, confirm:

1. Change Set is clear
2. Task order is clear
3. Each Task can run independently
4. Each Task has a validation method
5. No blocking business decisions
6. No blocking architecture decisions
7. Safe to enter IMPL
8. The Approval Record will authorize continuous execution across READY Tasks inside this PLAN scope

After Human Approval（人工批准）, persist the decision as an Approval Record
under `.ai/state/approvals/<approval-id>.yaml` and reference it from
`.ai/state/execution-state.yaml`. Do not rely only on chat, Markdown prose, or
Handoff.
