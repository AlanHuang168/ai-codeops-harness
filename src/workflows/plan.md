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
