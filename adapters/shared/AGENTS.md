# AI Engineering Entry

## Goal

This file is the entry point for AI-assisted development in this workspace.

It applies to Codex, Claude Code, OpenCode, and other project-level coding agents.

This file only defines:

* Bootstrap
* Workflow routing
* Progressive disclosure
* Change control
* Definition of Done

Project facts, architecture context, system boundaries, and current decisions are maintained in Project Context（项目上下文）and ADRs.

Project Context lives in `docs/project/` and follows `docs/harness/PROJECT-CONTEXT-CONTRACT.md`.

Compatibility（兼容期）: during the current migration the legacy root context files remain in place and authoritative; `docs/project/` mirrors them. Neither is deleted in this phase.

## Bootstrap

Before starting a development task:

1. Read the Project Context（项目上下文）entry: `docs/project/PROJECT.md`, and the tool-specific adapter file when one exists.
2. Identify the target subsystem.
3. Read the target subsystem's relevant:

   * `AGENTS.md`
   * the subsystem's AI adapter file, if present
   * `README.md`
   * ADRs
   * contracts
   * docs
4. Inspect the current implementation when needed.
5. Preserve existing user changes.
6. Do not load the entire `.ai/` directory by default.

## Session Bootstrap

At the start of a new session, recover project execution state in this order:

1. Read `AGENTS.md`.
2. Read `.ai/state/execution-state.yaml`.
3. Read `docs/handoff/HANDOFF-current.md`.
4. Read the Active PRD, ADR, and PLAN listed by the execution state.
5. Read `.ai/workflows/orchestrator.md`.
6. Perform a Current Reality Check（当前代码事实检查） against the relevant repository, schema, contracts, and validation evidence.

Current Reality（当前代码事实） has priority over `execution-state.yaml`. If the state and implementation evidence disagree, classify it as State Drift（状态漂移）, stop execution, and reconcile（校准） the state before continuing. Do not blindly trust cross-session state.

## Harness V2 Session Bootstrap

Harness V2 preserves the existing PRD → ADR → PLAN → DAG → Task State → Validation architecture and adds low-cost Runtime Recovery（运行时恢复） for cross Session（跨会话）, cross AI（跨 AI）, and Token Limit Interruption（Token 限额中断） recovery.

Harness V2 is the default recovery contract; V1 Governance Rules（治理规则） and approved project artifacts remain authoritative for scope and exit gates.

Default execution mode（默认执行模式） is `plan_continuous`. Accepted PLAN
（已接受计划） is the Runtime Unit（运行单元） and Authorization Unit（授权单元）;
Task（任务） is the Execution Unit（执行单元）; Human Gate（人工门禁） is the
Decision Unit（决策单元）.

An active PLAN Approval Record（计划审批记录） authorizes continuous execution
inside the accepted PLAN scope. Do not ask the Human to approve each normal
Task, next READY Task, PLAN-authorized test, checkpoint, state update,
documentation sync, or ordinary in-scope validation fix. Task Completed
（任务完成） is not a Human Gate.

Human Approval（人工审批） must be persisted as a machine-readable Approval
Record（审批记录） under `.ai/state/approvals/<approval-id>.yaml`. Conversation
approval without a persisted Runtime record is not sufficient for reliable
Resume（恢复） or Cross-Agent Recovery（跨 Agent 恢复）.

V2 distinguishes:

- Governance Rules（治理规则）: `AGENTS.md`, `.ai/workflows/*`, `.ai/rules/*`, Accepted PRD（已接受需求）, Accepted ADR（已接受架构决策）, Approved PLAN（已批准计划）. These define gates and allowed work.
- Runtime Facts（运行时事实）: `.ai/state/execution-state.yaml`, Approval Record（审批记录）, per-task Checkpoint（按任务检查点）, Handoff（交接）, and Current Reality Check（当前事实检查） evidence. These record where execution stopped and what Human Decisions（人工决策） were persisted.

State（状态） is authoritative only as Recovery Summary（恢复摘要）. It must not store detailed Validation Logs（验证日志）, command output, secrets, tokens, cookies, database connection values, raw PII, or long narrative history. State cannot redefine PRD / ADR / PLAN / Workflow Exit Gate（退出门禁）.

Handoff（交接） is Non-authoritative（非权威摘要）. Use it for human and cross-AI reading only; never let it override State, Checkpoint, Governance Rules, or Current Reality.

Checkpoint State（检查点状态） is not Current Executable State（当前可执行状态）.
Before resuming any checkpoint whose local state is `INTERRUPTED`, `ESCALATED`,
`BLOCKED`, or `APPROVAL_REQUIRED`, run Historical Checkpoint Reconciliation
（历史检查点对账） against current Runtime Reality.

Reconciliation authority order:

1. Newer Accepted Controlling Artifact（更新的已接受控制产物）
2. Top-level Runtime State（顶层运行状态）
3. Current Active PLAN（当前活跃计划）
4. Later Task / Checkpoint Evidence（后续任务 / 检查点证据）
5. Historical Checkpoint Local State（历史检查点本地状态）

Approval recovery authority order:

1. Accepted Controlling Artifact（已接受控制产物）
2. Active Machine-Readable Approval Record（活跃机器可读审批记录）
3. Top-level Runtime State（顶层运行状态）
4. Checkpoint Evidence（检查点证据）
5. Handoff（交接）
6. Conversation Context（对话上下文）

Approval Record cannot expand artifact scope. If work is outside the accepted
artifact, route through PLAN / Contract / ADR instead of relying on approval.

Default V2 Bootstrap reads at most 5 Core Artifacts（核心产物）:

1. `AGENTS.md`
2. `.ai/state/execution-state.yaml`
3. `docs/handoff/HANDOFF-current.md`
4. Selected Workflow（选定工作流）
5. Active controlling artifact（当前控制产物）: PRD, ADR, or PLAN

If there is no State Drift（状态漂移） and no `RUNNING` / `INTERRUPTED` task, do not expand scanning beyond the current task target. Context Budget（上下文预算） is controlled by `max_artifacts`, `max_expansions`, and explicit Expand Triggers（扩展触发条件）; token percentage is only a Soft Indicator（软指标）.

Loading the active Approval Record referenced by the current controlling
artifact is an explicit Expand Trigger（扩展触发条件）. Load only the matching
`.ai/state/approvals/<approval-id>.yaml`; do not scan all approvals by default.

### Project Context Resolution（项目上下文解析）

State（状态） carries a Project Context Reference（项目上下文引用） under `project_context`: the context directory, its entry document, the governing contract, and which location is authoritative. It carries **only the reference**, never the project facts themselves.

Resolution rules:

- Project Context is **not** part of the 5 Core Artifacts default. The 5-artifact default is unchanged.
- Resolve Project Context **on demand**, and only when the task actually needs project facts, system boundaries, domain terms, or project conventions, or when a Current Reality Check requires ownership or boundary information.
- Reading Project Context is an explicit **Expand Trigger（扩展触发条件）**; load the entry document first and only the further context documents the task requires.
- If `project_context` is missing from State, recovery still proceeds; report the missing reference instead of guessing a location.
- Project facts must never be copied into State, Checkpoint（检查点）, or Handoff（交接）. Those hold recovery facts and summaries only.

When the user only types “继续”:

1. Load the V2 Bootstrap Core Artifacts（启动核心产物） within the 5-artifact default.
2. Validate the shape of `execution-state.yaml`.
3. Identify the Current Active PLAN and newer Accepted controlling artifacts.
4. Load the active Approval Record for the current controlling artifact from `.ai/state/approvals/`.
5. Confirm the Approval Record is active, matches the artifact, and covers the requested action with `scope.allow` and no matching `scope.deny`.
6. If approval is missing, rejected, changes_requested, superseded, revoked, expired, or denied by scope, classify `APPROVAL_REQUIRED`.
7. Reconcile candidate `RUNNING`, `INTERRUPTED`, `ESCALATED`, `BLOCKED`, and `APPROVAL_REQUIRED` checkpoints before deciding what to do.
8. Convert any legacy `RUNNING` task without Active Executor Proof（活跃执行器证明） to `INTERRUPTED`（已中断） only when reconciliation keeps it `ACTIVE`.
9. Prefer reconciled `ACTIVE` interrupted work over reconciled `READY` work.
10. If exactly one reconciled `ACTIVE` interrupted task exists, load only that task's `.ai/state/checkpoints/tasks/<task-id>.yaml` and resume or rerun from its Checkpoint（检查点） and Reality Anchor（事实锚点）.
11. If multiple reconciled `ACTIVE` interrupted tasks exist, stop and ask the user to choose.
12. If no reconciled `ACTIVE` interrupted task exists and reconciled `READY` tasks exist, let the Orchestrator（任务编排器） choose by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）.
13. If the active PLAN is Approved, the Approval Record covers the action, and no Human Gate is active, continue from the selected Task without asking for PLAN approval again.
14. If no reconciled `ACTIVE` or `READY` task exists and all Current Active PLAN Tasks are `COMPLETE`, set `PLAN_COMPLETE` and produce the Final Report（最终报告）.
15. If only `SUPERSEDED`, `RESOLVED`, or `HISTORICAL` candidates remain, report the reconciliation result and do not resume them.
16. If current `BLOCKED_EXTERNAL` or `APPROVAL_REQUIRED` work remains, stop and report the blocking terminal state.

Checkpoint（检查点） files are per task:

```text
.ai/state/checkpoints/tasks/<task-id>.yaml
```

Checkpoint Lifecycle（检查点生命周期）:

```text
CREATED → UPDATED → VALIDATED → CLOSED / INTERRUPTED
```

COMPLETE Task（已完成任务） defaults to no Checkpoint loading. A closed Checkpoint may be loaded only for audit, State Drift, missing evidence, or explicit user request. `RUNNING` / `INTERRUPTED` tasks must be reconciled, then resolved from Checkpoint + Reality Anchor only if still `ACTIVE`; never guess them as `COMPLETE`.

Checkpoint may declare `exclusive_resource`（独占资源）, such as an isolated test database or port, to prevent concurrent validation from corrupting shared test state.

Validation evidence must be classified as:

- Executed Test（已执行测试）
- Human Validation（人工验证）
- Code-path Review（代码路径审查）
- NOT RUN（未执行）

Stop for Human decision only on real Human Gates:

- Architecture Drift（架构漂移）
- Scope Expansion（范围扩张）
- Breaking Contract Change（破坏性契约变化）
- Security / Privacy Risk（安全 / 隐私风险）
- Destructive Action（破坏性操作）
- policy-gated External Side Effect（外部副作用），例如 `git push`、production deploy（生产部署）、public release（公开发布）、registry publish（注册表发布）
- Unrecoverable Validation Failure（不可恢复验证失败）
- Explicit Human Decision（显式人工决策）
- PLAN Complete（计划完成） final report

When Human gives an approval, rejection, changes request, or conditional
approval in the current session, persist it as an Approval Record and reference
it from `.ai/state/execution-state.yaml`. Do not only answer "approved" in
chat.

## Directory Boundaries

- `.ai` is Harness Runtime（Harness 运行时），用于 Workflow、Rule、Role、State 和调度运行信息。
- `docs` is Human / Project Artifacts（人工/项目产物），用于 PRD、ADR、PLAN、交接和其他项目文档。
- Human review documents must use English Term（中文解释） for key terms and conclusions.

## Workflow Routing

For non-trivial development tasks, read:

`.ai/workflows/router.md`

Select the latest safe workflow stage:

* `PRD` — business requirements are unclear.
* `ADR` — architecture decisions are unclear or outdated.
* `PLAN` — implementation scope or task ordering needs definition.
* `IMPL` — the task is sufficiently defined for direct implementation.

Do not mechanically execute the full:

`PRD → ADR → PLAN → IMPL`

Start from the latest stage that can safely complete the task.

## Workflow Loading

After routing, load only the selected workflow:

* `.ai/workflows/prd.md`
* `.ai/workflows/adr.md`
* `.ai/workflows/plan.md`
* `.ai/workflows/impl.md`

Escalate when upstream uncertainty is discovered:

* Business Drift → `PRD`
* Architecture Drift → `ADR`
* Plan Drift → `PLAN`
* Implementation Bug → remain in `IMPL`

Do not silently resolve upstream decisions in a downstream stage.

## Progressive Disclosure

Load only the minimum context required for the current task.

Do not load all:

* workflows
* roles
* rules
* skills

Simple tasks must not incur unrelated Harness context.

## Context Priority

When information conflicts, evaluate it in this order:

1. Explicit current user requirements
2. Current implementation evidence: code, schema, contracts, deployment
3. Accepted ADRs
4. Project Context（`docs/project/`）and subsystem context documents
5. `AGENTS.md`
6. Generic `.ai/` guidance

Implementation evidence does not automatically override an ADR.

If implementation and documented architecture disagree, treat it as potential Architecture Drift and route to `ADR`.

## Change Control

Default to:

* Minimum necessary changes
* Reuse existing patterns and capabilities
* Preserve existing user changes
* Avoid unrelated refactoring
* Avoid scope expansion
* Avoid unnecessary abstractions
* Avoid technology replacement

Before introducing dependencies, schema changes, contract changes, or cross-system changes, ensure the selected workflow permits the decision.

## Definition of Done

Before declaring a feature or bug fix complete:

1. Review impact on:

   * architecture
   * data ownership
   * contracts
   * dependencies
   * development workflow
2. Run applicable verification:

   * format
   * lint
   * typecheck
   * tests
   * build
3. Inspect the final diff and check for Scope Drift.
4. Evaluate documentation impact.
5. Synchronize affected:

   * Project Context（`docs/project/`）and the AI adapter file
   * ADRs
   * the system map
   * contracts
   * README / AGENTS documentation
6. Report:

   * implemented changes
   * actual validation results
   * remaining risks
   * follow-up items

Do not declare a task complete while required documentation is out of sync.

Never claim that a test or validation passed unless it was actually executed.
