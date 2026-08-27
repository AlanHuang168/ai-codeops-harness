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

1. Read the Project Context（项目上下文）entry: `docs/project/PROJECT.md`, and the AI adapter file for the agent in use.
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

V2 distinguishes:

- Governance Rules（治理规则）: `AGENTS.md`, `.ai/workflows/*`, `.ai/rules/*`, Accepted PRD（已接受需求）, Accepted ADR（已接受架构决策）, Approved PLAN（已批准计划）. These define gates and allowed work.
- Runtime Facts（运行时事实）: `.ai/state/execution-state.yaml`, per-task Checkpoint（按任务检查点）, Handoff（交接）, and Current Reality Check（当前事实检查） evidence. These record where execution stopped.

State（状态） is authoritative only as Recovery Summary（恢复摘要）. It must not store detailed Validation Logs（验证日志）, command output, secrets, tokens, cookies, database connection values, raw PII, or long narrative history. State cannot redefine PRD / ADR / PLAN / Workflow Exit Gate（退出门禁）.

Handoff（交接） is Non-authoritative（非权威摘要）. Use it for human and cross-AI reading only; never let it override State, Checkpoint, Governance Rules, or Current Reality.

Default V2 Bootstrap reads at most 5 Core Artifacts（核心产物）:

1. `AGENTS.md`
2. `.ai/state/execution-state.yaml`
3. `docs/handoff/HANDOFF-current.md`
4. Selected Workflow（选定工作流）
5. Active controlling artifact（当前控制产物）: PRD, ADR, or PLAN

If there is no State Drift（状态漂移） and no `RUNNING` / `INTERRUPTED` task, do not expand scanning beyond the current task target. Context Budget（上下文预算） is controlled by `max_artifacts`, `max_expansions`, and explicit Expand Triggers（扩展触发条件）; token percentage is only a Soft Indicator（软指标）.

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
3. Convert any legacy `RUNNING` task without Active Executor Proof（活跃执行器证明） to `INTERRUPTED`（已中断） before deciding what to do.
4. Prefer recovery of `INTERRUPTED` tasks over `READY` tasks.
5. If exactly one `INTERRUPTED` task exists, load only that task's `.ai/state/checkpoints/tasks/<task-id>.yaml` and resume or rerun from its Checkpoint（检查点） and Reality Anchor（事实锚点）.
6. If multiple `INTERRUPTED` tasks exist, stop and ask the user to choose.
7. If no `INTERRUPTED` task exists and exactly one `READY` task exists, continue that task.
8. If multiple `READY` tasks exist, let the Orchestrator（任务编排器） choose by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）.
9. If no `INTERRUPTED` or `READY` task exists, stop and report that there is nothing to continue.

Checkpoint（检查点） files are per task:

```text
.ai/state/checkpoints/tasks/<task-id>.yaml
```

Checkpoint Lifecycle（检查点生命周期）:

```text
CREATED → UPDATED → VALIDATED → CLOSED / INTERRUPTED
```

COMPLETE Task（已完成任务） defaults to no Checkpoint loading. A closed Checkpoint may be loaded only for audit, State Drift, missing evidence, or explicit user request. `RUNNING` / `INTERRUPTED` tasks must be resolved from Checkpoint + Reality Anchor; never guess them as `COMPLETE`.

Checkpoint may declare `exclusive_resource`（独占资源）, such as an isolated test database or port, to prevent concurrent validation from corrupting shared test state.

Validation evidence must be classified as:

- Executed Test（已执行测试）
- Human Validation（人工验证）
- Code-path Review（代码路径审查）
- NOT RUN（未执行）

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
