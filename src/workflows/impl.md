# IMPL Workflow

## Purpose

Implement the confirmed PLAN as a continuous authorized Runtime Unit（运行单元）,
while keeping each PLAN Task as an Execution Unit（执行单元） for scope,
validation, checkpointing, and recovery.

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
- PLAN is Approved（已批准） or the requested change is safe for direct IMPL
- Active Approval Record（活跃审批记录） exists when executing an approved artifact
- At least one Task is executable, resumable, or ready to be selected by the Orchestrator
- Dependencies for the selected Task are satisfied
- Target and Validation are defined
- No active Human Gate（人工决策门禁） is blocking execution

Otherwise, do not start implementation.

## Root Cause Gate（根因门禁）

For bug-fix Tasks, before any high-impact change, state and confirm:

```text
Symptom
-> Root Cause
-> Why existing tests missed it
-> Fix Strategy
-> Regression Protection
```

Rules:

- A high-impact fix must not proceed while the Root Cause is unknown. Record the
  symptom and stop for investigation instead of guessing.
- A low-impact, obviously-scoped fix may state the root cause inline in one or
  two lines; it does not need a separate document.
- Regression Protection must add or identify a regression case that fails before
  the fix and passes after it (see `testing.md` and `eval.md`).

Do not resolve a defect with a large refactor in place of a stated root cause.

## Process

### 1. Select Task

Execute one PLAN Task at a time, but do not treat Task completion as an
approval boundary. Under the default `plan_continuous` execution mode, the
Runtime continues from one ready Task to the next inside the Approved PLAN
scope until the PLAN is complete or a real Human Gate is reached.

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

If `execution_mode` is absent, assume `plan_continuous`. `task_gated` is a
compatibility mode only when explicitly declared by the Approved PLAN or
Runtime State.

Before executing an approved PLAN Task, verify the active Approval Record:

- matches the current PLAN artifact id and digest when available;
- has `decision: approved` or valid `conditionally_approved`;
- has `status: active`;
- is not expired, revoked, superseded, or historical;
- allows the requested action; and
- does not deny the requested action.

If no valid Approval Record exists, classify `APPROVAL_REQUIRED` rather than
using conversation memory, Handoff prose, or PLAN Markdown prose as approval
authority.

### 2. Pre-check

Before modifying, confirm:

- Git working-tree state
- Existing user changes
- Current Target content
- Whether Dependencies are satisfied
- Whether the current implementation still matches the PLAN

Stop when clear drift is found.

If the Task is resumed from `INTERRUPTED`, first confirm Historical Checkpoint
Reconciliation（历史检查点对账） classified it as `ACTIVE`. Then use Checkpoint
（检查点） + Reality Anchor（事实锚点） to decide whether to resume implementation
or rerun validation. Do not infer `COMPLETE` from chat history or checkpoint
local state alone.

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

Validate is the TEST（测试） step: it verifies code, interface, exception, and
contract correctness. It is **not** proof of business effect.

### 4b. EVAL（效果评估）

When the Task changes an effect-bearing subsystem — parser, algorithm, AI /
model, rule engine, or recommendation — run EVAL per `eval.md` after Validate:

- Run the existing regression cases（回归数据集）; `pytest passed` alone is not
  sufficient business-correctness evidence.
- Measure the applicable effect metric(s) against the project-defined target.
- Report each `result` as `PASS`, `FAIL`, `NOT_RUN`, or `BLOCKED`.

When the Task is not effect-bearing, record EVAL as `N/A` with a one-line reason.
Do not fabricate a metric.

On an Architecture Path（架构路径） change, also run the Architecture Fitness
Functions（架构适应度函数） affected by the change (see `eval.md` and `adr.md`):

- Run the fitness functions declared by the relevant Accepted ADR; report each
  `result` at its actual evidence level.
- A `FAIL` fitness function is Architecture Drift（架构漂移）: STOP and route to
  `ARCHITECTURE_DRIFT` / `APPROVAL_REQUIRED`; do not silently patch it in scope.
- When no fitness function applies, record architecture fitness as `N/A`.

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

Before Review passes, verify the Acceptance Contract（验收契约） defined by the
PLAN:

```yaml
acceptance:
  technical:
    - <technical acceptance item>
  business:
    - <business acceptance item, or N/A>
  architecture:
    - <fitness function id holds, or N/A>
```

- Technical Acceptance（技术验收） maps to TEST results.
- Business Acceptance（业务验收） maps to EVAL results (see `eval.md`).
- Architecture Acceptance（架构验收） maps to Architecture Fitness Function
  results (see `adr.md` and `eval.md`); present for Architecture Path changes,
  otherwise `N/A`.
- Review MUST NOT return PASS while any declared acceptance item is unmet or its
  EVAL / fitness result is `FAIL`. An unmet acceptance item is a Blocker finding.

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

Move to the next Task after completion when the active PLAN is Approved,
`execution_mode` is `plan_continuous`, and the active Approval Record covers
the next requested action.

For Harness V2 tasks, exit in this order:

```text
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> Select Next READY Task
```

Stop after DAG Recalculation only when a terminal condition is reached:

- `PLAN_COMPLETE`（计划完成）
- `APPROVAL_REQUIRED`（需要人工批准）
- `ARCHITECTURE_DRIFT`（架构漂移）
- `SCOPE_EXPANSION`（范围扩张）
- `SECURITY_GATE`（安全门禁）
- `DESTRUCTIVE_ACTION`（破坏性操作）
- `UNRECOVERABLE_FAILURE`（不可恢复失败）
- Explicit Human Decision（显式人工决策）

Task Completed（任务完成） is not a Human Gate.

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

Set Runtime terminal state to `ARCHITECTURE_DRIFT` / `APPROVAL_REQUIRED`.

### Plan Drift

Files, dependencies, order, or Change Set clearly invalidated:

STOP
→ PLAN

Set Runtime terminal state to `SCOPE_EXPANSION` / `APPROVAL_REQUIRED` when the
new work is outside the Approved PLAN scope. If the issue is a normal
implementation bug that can be fixed inside the current Task scope, keep it in
IMPL, fix it, revalidate, and continue.

Do not resolve an upstream decision problem on your own in IMPL.

## Change Control

Allowed:

- Minimal changes required by the current Task
- Necessary test fixes directly caused by the current Task
- Well-defined compatibility fixes
- Ordinary validation-failure fixes that remain inside the current Task and Approved PLAN scope
- PLAN-approved documentation synchronization
- PLAN-approved state and checkpoint updates covered by an active Approval Record

Forbidden:

- Unrelated refactoring
- Incidental optimization
- Tech-stack replacement
- Adding an unplanned dependency
- Extending Future Scope
- Modifying an Accepted ADR
- Treating Approval Record as permission to expand PLAN scope
- Proceeding with an action listed in `scope.deny`

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

## Release Gate（发布门禁）

When the change affects a deployable or distributable artifact (a service,
server, or published package), Code Done（代码完成） is not Delivery Done
（交付完成）. Apply `release.md` before declaring delivery complete:

- Check README, API usage, health check, deployment docs, upgrade procedure,
  rollback, smoke test, and runtime config; report each as `OK`, `MISSING`,
  `N/A`, or `BLOCKED`.
- Release, deploy, publish, push, and merge remain irreversible External Side
  Effects（外部副作用）: stop at `RELEASE_GATE` / `APPROVAL_REQUIRED` and wait for
  Human authorization regardless of Risk Tier.

For a library or non-deployable change, record the Release Gate as `N/A`.

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
→ Checkpoint / State Update
→ DAG Recalculation
→ Select Next READY Task or Terminal State

Each Task remains atomic for scope and validation. The default IMPL run is
continuous across Tasks inside one Approved PLAN.

Automatically start the next READY Task when:

- Current Task Status = COMPLETE
- Validation results recorded
- Checkpoint/State Update（检查点 / 状态更新） completed when Harness V2 applies
- DAG Recalculation（DAG 重新计算） completed when Harness V2 applies
- No unresolved Blocker
- No Business / Architecture / Plan Drift
- The next Task remains inside the Approved PLAN scope
- The active Approval Record covers the requested action
- No active Human Gate exists

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
- APPROVAL_REQUIRED

After COMPLETE:

Continue to the next READY Task under `plan_continuous`, or stop only for a
terminal state or explicit `task_gated` compatibility mode.
