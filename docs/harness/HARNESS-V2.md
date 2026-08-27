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
- `.ai/state/checkpoints/tasks/<task-id>.yaml`
- `docs/handoff/HANDOFF-current.md`
- Current Reality Check（当前事实检查） evidence

State（状态） is canonical only for runtime recovery. It records whether a task claims to be `READY`, `RUNNING`, `INTERRUPTED`, `BLOCKED`, `ESCALATED`, or `COMPLETE`, but it does not redefine PLAN Exit Gate（PLAN 退出门禁） or validation requirements.

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
3. Per-task Checkpoint（按任务检查点）
4. Handoff（非权威摘要）
5. Chat History（聊天历史，仅辅助）

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

workflow:
  current_stage: ORCHESTRATOR
  selected_workflow: .ai/workflows/orchestrator.md

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
    validation_summary:
      status: NOT_RUN
      evidence_kinds: []

interrupted_tasks:
  - Task-2
ready_tasks:
  - Task-3
blocked_tasks: []
escalated_tasks: []

recommended_next_action:
  type: RESUME_INTERRUPTED
  task: Task-2

security:
  secret_policy: no_secret_values
```

Allowed Task State（任务状态）:

- `NOT_STARTED`（未开始）
- `READY`（可执行）
- `RUNNING`（运行中）
- `INTERRUPTED`（已中断）
- `BLOCKED`（阻塞）
- `ESCALATED`（已升级）
- `COMPLETE`（已完成）

Validation Summary（验证摘要） must stay minimal:

- `status`: `PASS`, `FAIL`, `BLOCKED`, `NOT_RUN`, or `PARTIAL`
- `evidence_kinds`: list of evidence kinds
- `executed_at`: date/time when applicable
- `checkpoint_path`: only for active `RUNNING` / `INTERRUPTED` tasks

Detailed evidence belongs in Handoff（交接）, task-specific reports, or validation artifacts, not in State（状态）.

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
- `CLOSED`（已关闭）: task exited as `COMPLETE`, `BLOCKED`, or `ESCALATED`.
- `INTERRUPTED`（已中断）: execution stopped before normal closure because of session end, token limit, tool failure, or unknown active executor state.

Completion rules:

- COMPLETE Task（已完成任务） defaults to no Checkpoint loading.
- A closed Checkpoint may be loaded only for audit, State Drift, missing evidence, or explicit user request.
- A `RUNNING` task without Active Executor Proof（活跃执行器证明） must be converted to `INTERRUPTED` during recovery.
- An `INTERRUPTED` task must be resumed or rerun from Checkpoint + Reality Anchor; it must never be guessed as `COMPLETE`.

Active Executor Proof（活跃执行器证明） may include a still-running tool session, lock file with fresh timestamp, known process id verified alive, or another explicit runtime lease. Chat history alone is not proof.

## Resume Protocol（会话恢复协议）

When the user only types "继续"（continue）, the agent must follow this deterministic order:

1. Read no more than the Bootstrap Core Artifacts（启动核心产物） allowed by Context Loading Policy.
2. Validate `execution-state.yaml` shape.
3. Find `RUNNING` tasks. If any lack Active Executor Proof, mark them logically as `INTERRUPTED` for recovery and persist that correction when state updates are allowed.
4. Prefer `INTERRUPTED` tasks over `READY` tasks.
5. If exactly one `INTERRUPTED` task exists, load only that task's Checkpoint and run the Recovery State Machine（恢复状态机）.
6. If multiple `INTERRUPTED` tasks exist, STOP and ask the user to choose.
7. If no `INTERRUPTED` task exists and exactly one `READY` task exists, continue with that task.
8. If multiple `READY` tasks exist, the Orchestrator（任务编排器） chooses by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）.
9. If no `INTERRUPTED` or `READY` task exists, STOP and report that there is nothing to continue.

## Recovery State Machine（恢复状态机）

```text
START
-> Bootstrap Core Artifacts
-> Validate State
-> Convert stale RUNNING to INTERRUPTED when no Active Executor Proof exists
-> INTERRUPTED exists?
   yes -> load per-task Checkpoint
        -> Current Reality Check by Reality Anchor
        -> Drift?
           yes -> STATE_DRIFT -> STOP + Reconcile
           no  -> inspect checkpoint phase
   no  -> READY exists?
        yes -> Orchestrator selects task
        no  -> STOP
```

Checkpoint phase handling:

- `before_edit`: resume implementation.
- `after_edit_before_validation`: run required validation.
- `validation_started_no_result`: rerun validation; incomplete validation is not PASS.
- `validation_failed`: classify as Implementation Bug（实现缺陷）, Environment Blocker（环境阻塞）, Business Drift（业务漂移）, Architecture Drift（架构漂移）, Plan Drift（计划漂移）, or Security Gate（安全门禁）.
- `validation_passed_before_review`: resume review and Scope Drift（范围漂移） check.
- `review_passed_before_state_update`: update state, close checkpoint, recalculate DAG.
- `closed`: do not resume by default.

Exit rule:

```text
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> STOP
```

One V2 Atomic Task（原子任务） must not automatically continue into the next V2 task.

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
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> STOP
```

No V2 task may modify business code, existing PRD, existing ADR, or existing business PLAN unless that task is explicitly approved to do so.
