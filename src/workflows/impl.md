# IMPL Workflow

## Purpose

Implement the confirmed PLAN one atomic task at a time,
and use validation and review to keep the implementation consistent with the PRD, ADR, and PLAN.

IMPL is responsible for:

- Implement
- Validate
- Review
- Fix
- Report

IMPL does not redefine requirements, architecture, or implementation scope.

## Preconditions

Before entering IMPL, confirm:

- PLAN is clear
- The current Task is executable
- Dependencies are satisfied
- Target is confirmed
- Validation is defined
- No blocking decisions

Otherwise, do not start implementation.

## Process

### 1. Select Task

Execute only one PLAN Task at a time.

Read what the current Task needs:

- Goal
- Target
- Dependencies
- Changes
- Validation

Load as needed:

- Role
- Rule
- Skill

Do not load the entire Harness for a single Task.

For Harness V2, load a per-task Checkpoint（按任务检查点） only when the current Task is `RUNNING`（运行中） or `INTERRUPTED`（已中断）, or when audit / State Drift（状态漂移） / missing evidence / explicit user request requires it. COMPLETE Task（已完成任务） defaults to no Checkpoint loading.

### 2. Pre-check

Before modifying, confirm:

- Git working-tree state
- Existing user changes
- Current Target content
- Whether Dependencies are satisfied
- Whether the current implementation still matches the PLAN

Stop when clear drift is found.

If the Task is resumed from `INTERRUPTED`, use Checkpoint（检查点） + Reality Anchor（事实锚点） to decide whether to resume implementation or rerun validation. Do not infer `COMPLETE` from chat history.

### 3. Implement

Implement per the Task Changes.

Principles:

- Minimal change
- Reuse existing implementation
- Follow existing project patterns
- Do not expand Scope
- No incidental refactoring
- Do not modify unrelated files

### 4. Validate

Run the corresponding Validation immediately after finishing the current Task.

May include:

- Format
- Lint
- Type Check
- Unit Test
- Integration Test
- Build
- Manual Verification
- Failure Path
- Security Check

Report only actual results.

Classify every validation item as Executed Test（已执行测试）, Human Validation（人工验证）, Code-path Review（代码路径审查）, or NOT RUN（未执行）. Code-path Review is not equivalent to Executed Test, and NOT RUN must not be reported as PASS.

### 5. Review

Review from the perspectives relevant to the current Task:

- Correctness
- Scope
- Regression
- Data Consistency
- Security
- Compatibility
- Maintainability

Load only the necessary Reviewer / Rule.

### 6. Fix

When Validation or Review fails:

Determine the cause first.

If it belongs to the current Task:

→ Minimal fix
→ Re-validate
→ Review

If it does not belong to the current Task:

→ Do not expand the change scope
→ Record the problem

Do not resolve a local failure with large-scale refactoring.

### 7. Task Completion

A Task may complete only when:

- Goal is achieved
- Validation passes or the failure cause is clear
- Review has no blocking problems
- PRD / ADR is not violated
- Scope is not expanded

Move to the next Task after completion.

For Harness V2 tasks, exit in this order:

```text
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> STOP
```

State（状态） records only Recovery Summary（恢复摘要）: task status, checkpoint path, minimal Validation Summary（验证摘要）, ready / interrupted / blocked / escalated sets, and recommended next action. Detailed validation logs, command output, secrets, tokens, cookies, database connection values, raw PII, and long narrative history must not be written to State.

Checkpoint（检查点） files are per task at `.ai/state/checkpoints/tasks/<task-id>.yaml`. Checkpoint Lifecycle（检查点生命周期） is `CREATED -> UPDATED -> VALIDATED -> CLOSED / INTERRUPTED`. A `RUNNING` or `INTERRUPTED` checkpoint must include Reality Anchor（事实锚点） and may declare `exclusive_resource`（独占资源） when validation uses shared resources such as a test database or port.

Handoff（交接） is Non-authoritative（非权威摘要）. Use it for concise human / cross-AI reading only; never let it override State, Checkpoint, PRD, ADR, PLAN, Workflow, or Current Reality（当前事实）.

## Escalation

During implementation, if you find:

### Business Drift

Business rule missing, conflicting, or inconsistent with the PRD:

STOP
→ PRD

### Architecture Drift

System boundary, Data Owner, Contract, or architecture assumption invalidated:

STOP
→ ADR

### Plan Drift

Files, dependencies, order, or Change Set clearly invalidated:

STOP
→ PLAN

Do not resolve an upstream decision problem on your own in IMPL.

## Change Control

Allowed:

- Minimal changes required by the current Task
- Necessary test fixes directly caused by the current Task
- Well-defined compatibility fixes

Forbidden:

- Unrelated refactoring
- Incidental optimization
- Tech-stack replacement
- Adding an unplanned dependency
- Extending Future Scope
- Modifying an Accepted ADR

When you find something worth improving that is not part of the current Task:

Record it as a Follow-up,
do not implement it now.

## Documentation Sync

After all Tasks are done, check:

- Project Context
- AGENTS.md
- README
- ADR
- Contract
- Schema docs

> Project Context（项目上下文）resolves from the `project_context` reference in Runtime State; see the Project Context Resolution rule in `AGENTS.md`. Read it on demand only.

Sync only the docs actually affected.

Do not modify unaffected docs for form's sake.

## Completion

Before IMPL is done:

1. Check the status of all PLAN Tasks
2. Run the planned final validation
3. Check the Git diff
4. Check for Scope Drift
5. Check Documentation Impact
6. Report actual test results
7. Report remaining risks
8. Report Follow-ups

Declare completion only when the Definition of Done is met.

## Final Output

At minimum:

1. Implemented
2. Changed Files
3. Validation Results
4. Review Findings
5. Documentation Updates
6. Remaining Risks
7. Follow-up

## Forbidden

- Developing freely and skipping PLAN Tasks
- Modifying multiple unrelated Tasks at once
- Changing the PRD on your own
- Changing the ADR on your own
- Hiding test failures
- Claiming unexecuted tests passed
- Deleting existing user changes
- Using refactoring to mask the current problem
- Implementing Future Scope early because you discovered it

## Atomic Task Lifecycle

Pre-check
→ Load Task Context
→ Implement
→ Validate
→ Review
→ Task Complete
→ Stop

Each IMPL run executes only one Atomic Task by default.

Do not automatically start the next Task.

The next Task requires:
- Current Task Status = COMPLETE
- Validation results recorded
- Checkpoint/State Update（检查点 / 状态更新） completed when Harness V2 applies
- DAG Recalculation（DAG 重新计算） completed when Harness V2 applies
- No unresolved Blocker
- No Business / Architecture / Plan Drift
- Explicit continuation or a new Router run

## Task Exit Gate

An Atomic Task is COMPLETE only when:

- Scope matches the Approved PLAN Task
- Required changes are implemented
- Applicable validation was actually executed
- Validation status is accurately reported
- No unresolved Blocker remains
- No unhandled Drift remains
- Final diff was reviewed for Scope Drift

Allowed Task Status:

- COMPLETE
- CHANGES REQUIRED
- BLOCKED
- ESCALATED

After COMPLETE:

STOP.

Do not automatically execute the next Atomic Task.
