# AI Project Workflow / Agent Harness V2

Status: Adopted Default
Date: 2026-08-27
Scope: Harness runtime recovery, checkpointing, context loading, and cross-AI handoff.

## Purpose（目的）

Harness V2 preserves the V1 governance flow:

```text
PRD -> ADR -> PLAN -> DAG -> Task State -> Validation
```

V2 adds a Runtime Recovery Layer（运行时恢复层） so Codex, Claude Code, Cursor, OpenCode, and other coding agents can recover cheaply after a new Session（会话）, a different AI, or a Token Limit Interruption（Token 限额中断）.

V2 also defines Accepted PLAN（已接受计划） as the Runtime Authorization
Boundary（运行授权边界）. Human-in-the-loop（人在回路） means Human owns key
decisions; it does not mean Human approves every normal execution step.

Human Approval（人工审批） is a persisted Runtime Fact（运行事实）. Conversation
approval without a machine-readable Runtime record is not sufficient for
reliable Resume（恢复） or Cross-Agent Recovery（跨 Agent 恢复）.

V2 does not replace the existing PRD / ADR / PLAN / Workflow architecture and must not rewrite stable V1 Harness behavior for its own sake.

## Adoption（采用状态）

Harness V2 is the default Runtime Recovery（运行时恢复） contract for new sessions and cross-AI handoff. Existing V1 Governance Rules（治理规则） remain in force, and V2 adoption does not alter accepted PRD, ADR, or business PLAN artifacts.

## Architecture（架构）

Harness V2 separates Governance Rules（治理规则） from Runtime Facts（运行时事实）.

Governance Rules（治理规则） define what should happen:

- `AGENTS.md`
- `.ai/workflows/*.md`
- `.ai/rules/*.md`
- Accepted PRD（已接受需求）
- Accepted ADR（已接受架构决策）
- Approved PLAN（已批准计划）

Runtime Facts（运行时事实） record what has happened or where execution stopped:

- `.ai/state/execution-state.yaml`
- `.ai/state/approvals/<approval-id>.yaml`
- `.ai/state/checkpoints/tasks/<task-id>.yaml`
- `docs/handoff/HANDOFF-current.md`
- Current Reality Check（当前事实检查） evidence

State（状态） is canonical only for runtime recovery. It records whether a task claims to be `NOT_STARTED`, `READY`, `RUNNING`, `INTERRUPTED`, `BLOCKED`, `ESCALATED`, `APPROVAL_REQUIRED`, or `COMPLETE`, but it does not redefine PLAN Exit Gate（PLAN 退出门禁） or validation requirements.

Approval Record（审批记录） is canonical for persisted Human Decision（人工决策）.
Artifact（产物） defines what may be done; Approval Record defines whether Human
authorized executing that Artifact and with what restrictions. Approval must
not expand PRD / ADR / PLAN scope.

Default execution mode（默认执行模式） is `plan_continuous`. Under this mode,
Task（任务） is the Execution Unit（执行单元）, Accepted PLAN is the Runtime Unit
（运行单元） and Authorization Unit（授权单元）, and Human Gate（人工门禁） is the
Decision Unit（决策单元）.

Handoff（交接） is Non-authoritative（非权威摘要）. It is written for humans and other AI agents to read quickly, but it cannot override `execution-state.yaml`, Task Checkpoint（任务检查点）, or Current Reality（当前事实）.

## Authority Model（权威模型）

Decision Authority（决策权威）:

1. Explicit User Requirement（用户当前明确要求）
2. Accepted PRD（已接受需求）
3. Accepted ADR（已接受架构决策）
4. Approved PLAN（已批准计划）
5. Workflow / Rules（工作流 / 规则）

Runtime Authority（运行时权威）:

1. Current Reality Check（当前事实检查）
2. `execution-state.yaml` recovery summary（恢复摘要）
3. Active Machine-Readable Approval Record（活跃机器可读审批记录）
4. Per-task Checkpoint（按任务检查点）
5. Handoff（非权威摘要）
6. Chat History（聊天历史，仅辅助）

Approval Recovery Authority（审批恢复权威）:

1. Accepted Controlling Artifact（已接受控制产物）
2. Active Machine-Readable Approval Record（活跃机器可读审批记录）
3. Top-level Runtime State（顶层运行状态）
4. Checkpoint Evidence（检查点证据）
5. Handoff（交接）
6. Conversation Context（对话上下文）

Approval Record cannot override the Artifact itself. If requested work changes
scope, contract semantics, or architecture, route through the corresponding
PLAN / Contract / ADR workflow instead of treating approval as scope expansion.

Historical Checkpoint Reconciliation（历史检查点对账） uses this authority
order before any checkpoint can become executable:

1. Newer Accepted Controlling Artifact（更新的已接受控制产物）
2. Top-level Runtime State（顶层运行状态）
3. Current Active PLAN（当前活跃计划）
4. Later Task / Checkpoint Evidence（后续任务 / 检查点证据）
5. Historical Checkpoint Local State（历史检查点本地状态）

Checkpoint State（检查点状态） is not Current Executable State（当前可执行状态）.
A single historical checkpoint is evidence only; it must not decide resume
without reconciliation against current Runtime Reality（运行时事实）.

Conflict rules:

- State may say a task is `COMPLETE`, but the agent must verify that required Gate Evidence（门禁证据） exists when the task is relevant to the current recovery.
- State cannot lower or replace PRD / ADR / PLAN / Workflow Exit Gate requirements.
- If State, Checkpoint, and Current Reality disagree, classify State Drift（状态漂移） and stop for Reconcile（校准） unless the drift is purely historical and irrelevant to the current task.
- Accepted ADRs remain architecture authority. Current implementation evidence can reveal Architecture Drift（架构漂移）, but does not silently supersede an ADR.

## State Schema（状态模型）

`execution-state.yaml` stores only Recovery Summary（恢复摘要）. It must not store detailed Validation Logs（验证日志）, command output, secrets, tokens, cookies, database connection values, raw PII, or large prose histories.

Recommended V2 shape:

```yaml
schema_version: "2.0"
updated_at: "2026-08-27T00:00:00Z"

active_artifacts:
  prd:
    id: PRD-0001
    path: docs/prd/PRD-0001-example.md
    status: Accepted
    digest: sha256:...
  adr:
    id: ADR-0005
    path: docs/adr/ADR-0005-example.md
    status: Accepted
    digest: sha256:...
  plan:
    id: PLAN-0001
    path: docs/plans/PLAN-0001-example.md
    status: Approved
    digest: sha256:...
    approval_record_id: APPROVAL-0001
    risk_tier: standard   # optional; fast | standard | architecture; absent = standard

workflow:
  current_stage: ORCHESTRATOR
  selected_workflow: .ai/workflows/orchestrator.md
  terminal_state: null
  reconciliation_required: true

tasks:
  Task-1:
    status: COMPLETE
    checkpoint_path: null
    validation_summary:
      status: PASS
      evidence_kinds: [Executed Test]
      executed_at: "2026-08-27"
  Task-2:
    status: INTERRUPTED
    checkpoint_path: .ai/state/checkpoints/tasks/Task-2.yaml
    reconciliation:
      current_status: ACTIVE
      resolution_source: []
    validation_summary:
      status: NOT_RUN
      evidence_kinds: []

interrupted_tasks:
  - Task-2
ready_tasks:
  - Task-3
blocked_tasks: []
escalated_tasks: []
approval_required_tasks: []

approvals:
  records_dir: .ai/state/approvals
  active:
    - approval_id: APPROVAL-0001
      artifact:
        type: PLAN
        id: PLAN-0001
      path: .ai/state/approvals/APPROVAL-0001.yaml
      status: active
  superseded: []
  revoked: []

reconciliation_results:
  PLAN-0002-T4:
    checkpoint_local_state: ESCALATED
    historical_status: RESOLVED
    resolution_source:
      - ADR-0002
      - PLAN-0003
    current_executable: false

recommended_next_action:
  type: RESUME_INTERRUPTED
  task: Task-2
  requires_human_approval: false

security:
  secret_policy: no_secret_values
```

If an active PLAN Approval Record's `scope.execution_mode` is absent, Runtime
MUST assume `plan_continuous`. `task_gated` is a compatibility mode only when
the Approval Record, Approved PLAN, or Runtime State explicitly declares it.

Approved PLAN requires an active Approval Record to authorize normal execution
inside the accepted PLAN scope:

- PLAN Tasks（计划任务）;
- PLAN code changes（计划内代码修改）;
- PLAN tests, validation, and review（测试、验证和审查）;
- State and Checkpoint updates（状态和检查点更新）;
- necessary ordinary bug fixes inside current Task / PLAN scope（范围内普通缺陷修复）;
- documentation sync explicitly included by the PLAN（计划明确包含的文档同步）.

Do not request repeated Human Approval（人工批准） for these actions.
Task completion is not an approval boundary.

Conversation approval without persisted Runtime record must be converted to an
Approval Record before reliable Resume can depend on it.

Allowed Task State（任务状态）:

- `NOT_STARTED`（未开始）
- `READY`（可执行）
- `RUNNING`（运行中）
- `INTERRUPTED`（已中断）
- `BLOCKED`（阻塞）
- `ESCALATED`（已升级）
- `APPROVAL_REQUIRED`（需要批准）
- `COMPLETE`（已完成）

Validation Summary（验证摘要） must stay minimal:

- `status`: `PASS`, `FAIL`, `BLOCKED`, `NOT_RUN`, or `PARTIAL`
- `evidence_kinds`: list of evidence kinds
- `executed_at`: date/time when applicable
- `checkpoint_path`: only for active `RUNNING` / `INTERRUPTED` tasks

Detailed evidence belongs in Handoff（交接）, task-specific reports, or validation artifacts, not in State（状态）.

## Approval Record Model（审批记录模型）

Approval Record（审批记录） is a machine-readable Runtime Fact stored under:

```text
.ai/state/approvals/<approval-id>.yaml
```

Top-level `execution-state.yaml` carries only the approval index and active
record references. Handoff may reference an Approval Record, but Handoff is not
Approval Authority（审批权威）.

Approval storage must be machine-readable, deterministic, diff-friendly, and
directly loadable by Resume without conversation context.

Recommended shape:

```yaml
schema_version: "2.0"
approval_id: APPROVAL-0001

artifact:
  type: PLAN
  id: PLAN-0001
  path: docs/plans/PLAN-0001-example.md
  digest: sha256:...

decision: approved
status: active
approved_at: "2026-08-27T00:00:00Z"

risk_tier: standard   # optional; fast | standard | architecture; absent = standard

scope:
  execution_mode: plan_continuous
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

conditions: []

supersedes: []
superseded_by: null
expires_at: null

source:
  type: human_decision
  recorded_by: agent
  recorded_at: "2026-08-27T00:00:00Z"

notes: []
```

Required fields:

- `approval_id`
- `artifact.type`, `artifact.id`, and preferably `artifact.path` / `artifact.digest`
- `decision`
- `status`
- `approved_at` when the decision is approving execution
- `scope.allow`
- `scope.deny`
- `source.type`
- `supersedes`
- `superseded_by`

Decision values:

- `approved`
- `rejected`
- `changes_requested`
- `conditionally_approved`

Status values:

- `active`: Runtime may rely on this approval.
- `superseded`: newer controlling artifact or newer approval replaced it.
- `revoked`: Human explicitly revoked it.
- `historical`: retained as evidence only.

`conditionally_approved` may authorize execution only when every listed
condition is satisfied and the requested action is still inside artifact scope.

Scope semantics:

- `allow` lists action classes authorized by this approval.
- `deny` lists action classes explicitly not authorized.
- `deny` wins over `allow`.
- Approval does not define artifact scope; it only authorizes execution of an existing accepted artifact.
- If requested work is outside the artifact scope, classify Scope Expansion（范围扩张） and require a Human Gate.
- Keep action classes small and practical; do not turn this into a full permission matrix.

Restrictions example:

```yaml
scope:
  allow:
    - implementation
    - tests
    - local_commit
  deny:
    - git_push
    - production_deploy
    - public_release
```

In this example, `local_commit` may continue automatically, while `git_push`
is a policy-gated External Side Effect（外部副作用） and must stop at the
`APPROVAL_REQUIRED` terminal state.

Default PLAN Approval（默认计划审批） authorizes:

- `plan_execution`
- `implementation`
- `validation`
- `checkpoint_update`
- `state_update`
- `in_scope_bug_fix`
- `documentation_sync` when the PLAN explicitly includes it

Default PLAN Approval does not authorize:

- `destructive_operation`
- `production_deploy`
- `public_release`
- `registry_publish`
- `scope_expansion`

When Human gives a decision in-session, such as "approve", "continue with this
PLAN", or "allow A/B/C but do not push", the agent must persist an Approval
Record before relying on that decision for Runtime execution. Do not only write
"approved" in chat or Handoff.

Legacy fallback:

- If an older project has `PLAN status: Approved` but no Approval Record, do not silently treat it as unlimited authorization.
- If the controlling artifact clearly proves Human Approval occurred, create a legacy-derived Approval Record with `source.type: legacy_artifact_migration` and restrict it to the artifact's default scope.
- If approval evidence is insufficient, classify `APPROVAL_REQUIRED`.
- Natural-language Handoff is supporting evidence only and must not become final Approval Authority.

Lifecycle:

```text
Human Decision
-> Persist Approval Record
-> Runtime consumes approval
-> Task execution / Resume reuse
-> Newer controlling decision
-> superseded / revoked / historical
```

When a newer PLAN replaces an older PLAN, the older PLAN Approval Record must
not authorize the newer PLAN. Mark the old approval `superseded` or
`historical`, and create or reference a separate active approval for the newer
PLAN.

## Risk Tier and Acceptance Contract（风险分级与验收契约）

Risk Tier（风险分级） is an optional Runtime field that records how a change was
classified by the Change Risk Router（`src/workflows/risk-router.md`）. It is
additive: when absent, Runtime treats the change as `standard`.

```yaml
risk_tier: standard   # fast | standard | architecture
```

Tier to approval mapping:

| Tier | New Human Approvals | Added gates |
| --- | --- | --- |
| `fast` | 0 (in-scope authorization) | Root Cause Gate for bug fixes |
| `standard` | 1 (PLAN) | EVAL when effect-bearing, Acceptance Contract |
| `architecture` | key nodes: ADR + PLAN | EVAL, Acceptance Contract, Release Gate |

Risk Tier never lowers a real Human Gate. Irreversible operations — data
deletion, database Migration（迁移）, auth / authz change, breaking API, release,
and `git push` / merge / deploy / publish — keep their existing gate at any tier.

Acceptance Contract（验收契约） is an Exit-Gate input, not a new State object. A
PLAN declares it and IMPL Review verifies it before Task completion:

```yaml
acceptance:
  technical:      # TEST-level: code, interface, exception, contract
    - tests pass
    - api compatible
  business:       # EVAL-level: effect / output quality; see src/rules/eval.md
    - expected fixture outputs match
    - latency target satisfied
  architecture:   # optional; Architecture Fitness Functions; see src/workflows/adr.md
    - AFF-ADR-0005-1 holds
```

The optional `architecture` dimension holds Architecture Fitness Functions
（架构适应度函数） declared by an Accepted ADR. It is present for Architecture Path
（架构路径） changes and absent for Fast / Standard changes; when absent, behavior
is unchanged. A `FAIL` fitness function is an executable signal of Architecture
Drift（架构漂移） and routes to the existing `ARCHITECTURE_DRIFT` /
`APPROVAL_REQUIRED` terminal state, not a silent in-scope fix.

Review must not pass while a declared acceptance item is unmet or its EVAL /
fitness result is `FAIL`. Detailed EVAL logs stay out of State（状态）; only
minimal Validation Summary（验证摘要） is stored, consistent with the evidence
rules.

## Checkpoint Schema（检查点模型）

Checkpoint files are per-task. V2 does not use a single `current.yaml`.

Path:

```text
.ai/state/checkpoints/tasks/<task-id>.yaml
```

Recommended shape:

```yaml
schema_version: "2.0"
task_id: Task-2
plan_id: PLAN-0001
approval_record_id: APPROVAL-0001
lifecycle: UPDATED
updated_at: "2026-08-27T00:00:00Z"

task_scope:
  goal: "Short task goal"
  target_paths:
    - path/to/file
  allowed_changes:
    - "Minimal task-specific change"
  forbidden_changes:
    - "No PRD / ADR / approved PLAN change"

reality_anchor:
  repo_paths:
    - path/to/subrepo
  expected_changed_paths:
    - path/to/file
  artifact_digests:
    - path: docs/plans/PLAN-0001-example.md
      digest: sha256:...
  validation_artifacts:
    - name: typecheck
      kind: Executed Test
      status: NOT_RUN

progress:
  phase: after_edit_before_validation
  completed_steps:
    - precheck
    - implementation
  pending_steps:
    - validation
    - review
    - state_update

changed_paths:
  - path/to/file

exclusive_resource:
  required: false
  resources: []
  reason: null

validation:
  required:
    - name: typecheck
      command: npm run typecheck
      cwd: path/to/subrepo
      evidence_kind: Executed Test
      status: NOT_RUN
  completed: []

resume:
  default_action: RERUN_VALIDATION
  instruction: "Run validation, review diff, then update state."
  rerun_required: true

reconciliation:
  current_status: ACTIVE
  resolution_source: []
  checked_at: "2026-08-27T00:00:00Z"
  rationale: "Still belongs to the current active PLAN and has no later resolving evidence."

safety:
  secrets_stored: false
  pii_stored: false
```

Reality Anchor（事实锚点） is mandatory for `RUNNING` and `INTERRUPTED` checkpoints. It gives the next agent cheap evidence for Current Reality Check（当前事实检查） without scanning the repository.

`exclusive_resource` prevents shared-resource collisions such as resetting one isolated test database while another validation suite is still running.

Example:

```yaml
exclusive_resource:
  required: true
  resources:
    - postgres:{{TEST_DATABASE_NAME}}
    - port:{{TEST_SERVER_PORT}}
  reason: "Avoid concurrent fixture reset while API contract server is running."
```

## Project Context Reference（项目上下文引用）

State（状态） carries a pointer to Project Context（项目上下文）, never the project facts themselves:

```yaml
project_context:
  dir: {{CONTEXT_DIR}}
  entry: {{CONTEXT_DIR}}/PROJECT.md
  contract: docs/harness/PROJECT-CONTEXT-CONTRACT.md
  authority: {{CONTEXT_DIR}}
```

Rules:

- The reference keeps Runtime State（运行状态） free of project knowledge while still letting any agent resolve where the facts live.
- Project Context is resolved **on demand** and is **not** one of the 5 Bootstrap Core Artifacts（启动核心产物）; the default budget is unchanged and reading it is an explicit Expand Trigger（扩展触发条件）.
- If the reference is absent, recovery still proceeds; report the gap rather than guessing a location.
- Project facts must never be copied into State, Checkpoint（检查点）, or Handoff（交接）.

## Checkpoint Lifecycle（检查点生命周期）

```text
CREATED -> UPDATED -> VALIDATED -> CLOSED
CREATED -> INTERRUPTED
UPDATED -> INTERRUPTED
VALIDATED -> INTERRUPTED
```

Lifecycle definitions:

- `CREATED`（已创建）: Task scope, target, validation, and initial Reality Anchor are recorded.
- `UPDATED`（已更新）: progress or changed paths were updated after implementation activity.
- `VALIDATED`（已验证）: required validation summary was recorded.
- `CLOSED`（已关闭）: task exited as `COMPLETE`, `BLOCKED`, `ESCALATED`, or `APPROVAL_REQUIRED`.
- `INTERRUPTED`（已中断）: execution stopped before normal closure because of session end, token limit, tool failure, or unknown active executor state.

Completion rules:

- COMPLETE Task（已完成任务） defaults to no Checkpoint loading.
- A closed Checkpoint may be loaded only for audit, State Drift, missing evidence, or explicit user request.
- A `RUNNING` task without Active Executor Proof（活跃执行器证明） must be converted to `INTERRUPTED` during recovery.
- An `INTERRUPTED` task must be reconciled before it can be resumed or rerun from Checkpoint + Reality Anchor; it must never be guessed as `COMPLETE`.

Active Executor Proof（活跃执行器证明） may include a still-running tool session, lock file with fresh timestamp, known process id verified alive, or another explicit runtime lease. Chat history alone is not proof.

## Historical Checkpoint Reconciliation（历史检查点对账）

Resume MUST reconcile any historical checkpoint whose local state is
`INTERRUPTED`, `ESCALATED`, `BLOCKED`, or `APPROVAL_REQUIRED` before treating it
as current executable work.

Do not run this logic:

```text
if checkpoint.status == INTERRUPTED:
    resume()
```

Run this logic instead:

```text
reconciliation = reconcile(checkpoint, current_runtime_state)
if reconciliation.current_status in [ACTIVE, READY, BLOCKED_EXTERNAL, APPROVAL_REQUIRED]:
    handle_current_status(reconciliation)
else:
    keep_as_history()
```

Allowed reconciliation statuses（对账状态）:

- `ACTIVE`（活跃）: still belongs to the current active PLAN and remains resumable.
- `SUPERSEDED`（已被取代）: a newer Accepted controlling artifact or PLAN replaced the checkpoint's PLAN / Task scope.
- `RESOLVED`（已解决）: later accepted artifacts, approvals, or completed work resolved the condition.
- `HISTORICAL`（历史）: retained as evidence only and not part of current executable work.
- `READY`（可执行）: prior blocker is gone, the active PLAN still applies, and dependencies / gates are satisfied.
- `BLOCKED_EXTERNAL`（外部阻塞）: still blocked by an external condition outside the current agent's control.
- `APPROVAL_REQUIRED`（需要批准）: still requires a current Human Decision and no later approval exists.

Classification rules:

- If a newer Accepted ADR / Amendment / PLAN supersedes the checkpoint's controlling artifact, classify `SUPERSEDED` or `RESOLVED`.
- If top-level Runtime State marks the task complete, resolved, superseded, or outside the active PLAN, do not resume the checkpoint.
- If the checkpoint's task is not in the Current Active PLAN, classify `SUPERSEDED` or `HISTORICAL`.
- If later Task / Checkpoint Evidence proves the same issue was completed or replaced, classify `RESOLVED` or `HISTORICAL`.
- If an old `BLOCKED` condition is no longer present, the active PLAN still applies, and dependencies are satisfied, classify `READY`.
- If an old `APPROVAL_REQUIRED` has a later active Approval Record covering the same artifact and requested action, classify `RESOLVED` and do not ask approval again.
- Only classify `ACTIVE` when the checkpoint still belongs to the current active PLAN, has not been superseded or resolved, has no later completion evidence, and is currently executable or resumable.

When top-level Runtime State and one checkpoint disagree, report the
reconciliation result and the authority source used. Do not silently guess from
the checkpoint alone.

Example:

```yaml
task_id: PLAN-0002-T4
checkpoint_local_state: ESCALATED
historical_status: resolved
resolution_source:
  - ADR-0002
  - PLAN-0003
current_executable: false
```

## Resume Protocol（会话恢复协议）

When the user only types "继续"（continue）, the agent must follow this deterministic order:

1. Read no more than the Bootstrap Core Artifacts（启动核心产物） allowed by Context Loading Policy.
2. Validate `execution-state.yaml` shape.
3. Identify the Current Active PLAN and any newer Accepted controlling artifacts.
4. Read active Approval Record references from top-level State and load only the record(s) for the current controlling artifact.
5. Validate that the Approval Record is `active`, matches the current artifact id / digest when available, is not expired, is not superseded or revoked, and covers the requested action with `scope.allow` and no matching `scope.deny`.
6. If Approval Record is missing, rejected, changes_requested, superseded, revoked, expired, or does not cover the requested action, classify `APPROVAL_REQUIRED` and do not continue.
7. Find candidate `RUNNING`, `INTERRUPTED`, `ESCALATED`, `BLOCKED`, and `APPROVAL_REQUIRED` tasks or checkpoints.
8. Reconcile each candidate using Historical Checkpoint Reconciliation before selecting executable work.
9. Convert stale `RUNNING` tasks without Active Executor Proof to `INTERRUPTED` only after confirming they are still `ACTIVE`.
10. Prefer reconciled `ACTIVE` interrupted work over reconciled `READY` work.
11. If exactly one reconciled `ACTIVE` interrupted task exists, load only that task's Checkpoint and run the Recovery State Machine（恢复状态机）.
12. If multiple reconciled `ACTIVE` interrupted tasks exist, STOP and ask the user to choose.
13. If no reconciled `ACTIVE` interrupted task exists and reconciled `READY` tasks exist, the Orchestrator（任务编排器） chooses by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）.
14. If the active PLAN is Approved, active Approval Record covers the selected action, and no Human Gate is active, continue from the selected Task without asking for PLAN approval again.
15. If no reconciled `ACTIVE` or `READY` task exists and all Current Active PLAN Tasks are `COMPLETE`, set `PLAN_COMPLETE` and produce the Final Report（最终报告）.
16. If only `SUPERSEDED`, `RESOLVED`, or `HISTORICAL` candidates remain, report the reconciliation result and do not resume them.
17. If current `BLOCKED_EXTERNAL` or `APPROVAL_REQUIRED` work remains, STOP and report the blocking terminal state.

## Recovery State Machine（恢复状态机）

```text
START
-> Bootstrap Core Artifacts
-> Validate State
-> Identify Current Active PLAN and newer Accepted controlling artifacts
-> Load matching active Approval Record
-> Requested action covered?
   no  -> APPROVAL_REQUIRED -> STOP
   yes -> continue
-> Reconcile historical checkpoint candidates
-> Approved PLAN exists?
   yes -> use active Approval Record authorization scope
   no  -> route to PLAN approval or direct IMPL rules
-> Reconciled ACTIVE interrupted work exists?
   yes -> load per-task Checkpoint
        -> Current Reality Check by Reality Anchor
        -> Drift?
           yes -> STATE_DRIFT -> STOP + Reconcile
           no  -> inspect checkpoint phase
   no  -> Reconciled READY work exists?
        yes -> Orchestrator selects task
        no  -> report PLAN_COMPLETE, historical-only result, BLOCKED_EXTERNAL, or APPROVAL_REQUIRED
```

Checkpoint phase handling:

- `before_edit`: resume implementation.
- `after_edit_before_validation`: run required validation.
- `validation_started_no_result`: rerun validation; incomplete validation is not PASS.
- `validation_failed`: classify as Implementation Bug（实现缺陷）, Environment Blocker（环境阻塞）, Business Drift（业务漂移）, Architecture Drift（架构漂移）, Plan Drift（计划漂移）, or Security Gate（安全门禁）.
- `validation_passed_before_review`: resume review and Scope Drift（范围漂移） check.
- `review_passed_before_state_update`: update state, close checkpoint, recalculate DAG.
- `closed`: do not resume by default.

Default continuous PLAN execution:

```text
PLAN_APPROVED
-> SELECT_READY_TASK
-> TASK_RUNNING
-> VALIDATE
-> CHECKPOINT
-> DAG_RECALCULATE
-> SELECT_READY_TASK
```

If a READY Task exists and no terminal state exists, Runtime MUST continue
automatically. One V2 Atomic Task（原子任务） remains the unit of validation and
checkpointing, but it must not force Human Approval before the next normal
Task.

Terminal states:

- `PLAN_COMPLETE`（计划完成）
- `APPROVAL_REQUIRED`（需要人工批准）
- `ARCHITECTURE_DRIFT`（架构漂移）
- `SCOPE_EXPANSION`（范围扩张）
- `SECURITY_GATE`（安全门禁）
- `DESTRUCTIVE_ACTION`（破坏性操作）
- `RELEASE_GATE`（发布门禁）
- `UNRECOVERABLE_FAILURE`（不可恢复失败）

`RELEASE_GATE`（发布门禁） is the release / deploy / publish specialization of the
policy-gated External Side Effect（外部副作用）. It always requires a Human Gate
regardless of Risk Tier（风险分级）. See `src/rules/release.md`.

Human Gate Policy（人工门禁策略）:

- Architecture Drift: Current Reality conflicts with Accepted ADR / Architecture.
- Scope Expansion: required work is outside the Approved PLAN scope.
- Breaking Contract Change: breaking semantics of an Accepted Contract must change.
- Security / Privacy Risk: new credential, data exposure, or security risk appears.
- Destructive Action: irreversible migration, production data deletion, or production-impacting destructive operation.
- External Side Effect: policy / profile decides whether actions such as `git push`, production deploy, public release, or registry publish require Human Gate.
- Unrecoverable Validation Failure: failure cannot reasonably be fixed inside Approved PLAN scope.
- Explicit Human Decision: the PLAN declares `requires_human_decision: true`.
- PLAN Complete: produce the final result report.

The following are not Human Gates by themselves:

- ordinary Task completion;
- a next Task becoming READY;
- ordinary code changes inside PLAN scope;
- PLAN-authorized tests and documentation sync;
- Checkpoint or State updates;
- validation failures that can be fixed in scope;
- normal refactor that does not change Accepted Contract / Architecture;
- satisfied same-PLAN Task dependencies.

## Progressive Context Loading（渐进式上下文加载）

Default Bootstrap reads at most 5 Core Artifacts（核心产物）:

1. `AGENTS.md`
2. `.ai/state/execution-state.yaml`
3. `docs/handoff/HANDOFF-current.md`
4. Selected Workflow（选定工作流）
5. Active controlling artifact（当前控制产物）: PRD, ADR, or PLAN

No State Drift（无状态漂移） means no broader scan.

Context Budget（上下文预算） is controlled by:

- `max_artifacts`
- `max_expansions`
- explicit Expand Triggers（扩展触发条件）

Token percentage is a Soft Indicator（软指标） only.

Recommended default:

```yaml
context_budget:
  max_artifacts: 5
  max_expansions: 3
  soft_token_hint: "Keep bootstrap under roughly 10-15% of available context."
```

Expand Triggers（扩展触发条件）:

- Active controlling artifact references an Approval Record.
- Checkpoint is required for `RUNNING` / `INTERRUPTED`.
- Reality Anchor cannot be verified.
- Active artifact digest mismatch.
- Target path missing.
- Dirty working tree overlaps target paths.
- Required validation evidence missing.
- User asks for audit, design, or review beyond the current task.
- Workflow explicitly requires a role, rule, contract, or subsystem doc.

Forbidden by default:

- Loading all workflows.
- Loading all rules, roles, or skills.
- Traversing the whole repository.
- Reading secret-bearing `.env*` files.
- Treating chat history as the only recovery source.

## Validation Evidence（验证证据）

Allowed evidence kinds:

- `Executed Test`（已执行测试）: command, tool, fixture, or system check actually ran.
- `Human Validation`（人工验证）: user or human reviewer actually performed the validation.
- `Code-path Review`（代码路径审查）: implementation path was inspected; not equivalent to a test.
- `NOT RUN`（未执行）: validation was not executed and must not be inferred as PASS.

State stores only minimal Validation Summary（验证摘要）. Handoff or dedicated reports may include concise human-readable details.

## Cross-AI Handoff（跨 AI 交接）

All AI agents must be able to continue from files, not from chat memory.

Rules:

- Use YAML for state and checkpoint facts.
- Use Markdown for handoff summaries.
- Handoff is Non-authoritative（非权威摘要）.
- Store paths, task ids, statuses, evidence kinds, and summaries; do not store secrets.
- Record side effects as `changed_paths`.
- Record recovery instructions in `resume.instruction`.
- Keep command strings portable and include `cwd` when relevant.
- Prefer stable English enum values with English Term（中文解释） in human-facing docs.

## V1 to V2 Migration Plan（V1 到 V2 迁移计划）

V2 must be introduced as small Harness tasks:

1. `V2-1: Write V2 Spec（编写 V2 规范）`
2. `V2-2: Update AGENTS Entry（更新入口）`
3. `V2-3: Add Checkpoint Directory（增加检查点目录）`
4. `V2-4: Migrate State Summary（迁移状态摘要）`
5. `V2-5: Patch Workflow Hooks（补充工作流钩子）`
6. `V2-6: Evidence Classification Sync（证据分类同步）`
7. `V2-7: Handoff Contract（交接契约）`
8. `V2-8: Dry Run（演练）`
9. `V2-9: Adopt V2 Default（设为默认）`

Each V2 task follows:

```text
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> Select Next READY Task
```

No V2 task may modify business code, existing PRD, existing ADR, or existing business PLAN unless that task is explicitly approved to do so.

## Approval Record Validation Scenarios（审批记录验证场景）

These scenarios validate machine-readable Human Decision persistence and reuse.

| Case | Input | Expected Approval State | Runtime Behavior |
| --- | --- | --- | --- |
| 1. Basic Approval（基础审批） | `PLAN-0001` receives Human approval | Create `APPROVAL-0001` with `decision: approved`, `status: active` | Resume reuses it; no repeated approval question |
| 2. Cross-Agent Recovery（跨 Agent 恢复） | Codex records `PLAN-0003` approval, completes `T1`, then stops | `APPROVAL-0003` remains active and references `PLAN-0003` | Claude or another agent reads it and continues next READY Task |
| 3. Restricted Scope（受限范围） | Approval allows `implementation`, `tests`; denies `production_deploy` | Record `allow` and `deny` exactly | Implementation/tests continue; production deploy stops at Human Gate |
| 4. Rejected（拒绝） | `decision: rejected` | Record retained with no executable authorization | Runtime must not enter IMPL for that artifact |
| 5. Superseded PLAN（计划被取代） | `PLAN-0001` approved, later `PLAN-0002` replaces it | `PLAN-0001` approval becomes `superseded` / `historical`; `PLAN-0002` needs its own active approval | Old approval must not authorize new PLAN |
| 6. Historical Approval Required Checkpoint（历史需审批检查点） | Old checkpoint says `APPROVAL_REQUIRED`; later active Approval Record exists | Reconciliation = `RESOLVED` | Do not ask approval again |
| 7. Approval Does Not Expand Scope（审批不扩范围） | PLAN allows subsystem A; execution discovers subsystem B is needed | Approval remains active only for subsystem A scope | Stop at Scope Expansion Human Gate |
| 8. Context Loss（上下文丢失） | Chat history unavailable; artifact, Approval Record, and State exist | Approval can still be read from `.ai/state/approvals/` | Runtime recovers authorization without conversation context |

## Historical Checkpoint Reconciliation Validation Scenarios（历史检查点对账验证场景）

These scenarios validate Resume / Checkpoint reconciliation only.

| Case | Input | Expected Reconciliation | Resume Behavior |
| --- | --- | --- | --- |
| 1. Still active interrupted task（仍活跃的中断任务） | Old `T4` is `INTERRUPTED`; same active PLAN still applies; no later resolution exists | `ACTIVE` | Resume `T4` from checkpoint |
| 2. Escalation resolved by newer artifacts（升级已被新产物解决） | Old `PLAN-0002-T4` is `ESCALATED`; later `ADR-0002` Accepted and `PLAN-0003` Accepted / completed | `RESOLVED` or `HISTORICAL`; `resolution_source: [ADR-0002, PLAN-0003]` | Do not resume `PLAN-0002-T4` |
| 3. Blocker cleared（阻塞已恢复） | Old `BLOCKED`; external condition is now available; active PLAN still applies | `READY` | Select through Orchestrator |
| 4. Approval already granted（批准已存在） | Old `APPROVAL_REQUIRED`; later active Approval Record covers the same artifact and action | `RESOLVED` | Do not request approval again |
| 5. Old PLAN superseded（旧计划被取代） | Old PLAN checkpoint unfinished; newer Accepted PLAN supersedes that scope | `SUPERSEDED` | Do not resume old PLAN checkpoint |
| 6. State / checkpoint conflict（状态与检查点冲突） | Top-level State and one checkpoint disagree | Report reconciliation result and authority source | Use Authority Order; do not silently guess |

Acceptance example:

```text
PLAN-0002-T4 local checkpoint = ESCALATED / INTERRUPTED
ADR-0002 = Accepted
PLAN-0003 = Accepted
PLAN-0003 tasks = COMPLETE
=> PLAN-0002-T4 historical_status = resolved
=> current_executable = false
```

## Continuous PLAN Execution Validation Scenarios（连续计划执行验证场景）

These scenarios validate Harness protocol behavior, not a resident runtime
engine.

| Case | Input | Expected Runtime Result | Human Gate Count |
| --- | --- | --- | --- |
| 1. Normal continuous execution（正常连续执行） | Approved PLAN: `T1 -> T2 -> T3` | `T1 COMPLETE -> T2 COMPLETE -> T3 COMPLETE -> PLAN_COMPLETE` | 0 |
| 2. Architecture Drift（架构漂移） | `T1 COMPLETE`, `T2` discovers ADR / Current Reality conflict | Stop at `ARCHITECTURE_DRIFT` / `APPROVAL_REQUIRED`; do not run `T3` | 1 |
| 3. Ordinary Validation Failure（普通验证失败） | `T2` test fails and can be fixed inside `T2` scope | Fix in scope, rerun validation, then continue `T3` | 0 |
| 4. Scope Expansion（范围扩张） | `T2` requires a new subsystem or feature outside PLAN | Stop at `SCOPE_EXPANSION` / `APPROVAL_REQUIRED` | 1 |
| 5. Recovery（恢复） | PLAN Approved, `T1 COMPLETE`, agent interrupted | Next agent reads State + Approved PLAN and continues from `T2` / next READY Task | 0 |
| 6. Explicit Gate（显式门禁） | PLAN Task declares `requires_human_decision: true` | Stop at that Task before the decision is made | 1 |
| 7. Feature Complete（功能完成） | Last Task completes and final validation is done | Set `PLAN_COMPLETE`, generate Final Report, no meaningless continue gate | 0 |

Incorrect:

```text
PLAN Approved -> T1 -> Ask -> T2 -> Ask -> T3
```

Correct:

```text
PLAN Approved -> T1 -> T2 -> T3 -> PLAN Complete
```
