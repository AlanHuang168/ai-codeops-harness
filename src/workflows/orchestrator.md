# Task Orchestrator Workflow

## Purpose（目的）

Task Orchestrator（任务编排器）负责根据 Approved PLAN（已批准实施计划）
连续调度 Atomic Task（原子任务）。

它不修改 PRD、ADR、PLAN 或业务代码，也不替代 Router、PLAN 或 IMPL Workflow。
它选择下一个可执行 Task，并在默认 `plan_continuous` 模式下把执行权连续交给
IMPL，直到 PLAN 完成或触发真正的 Human Gate（人工决策门禁）。

## Inputs（输入）

调度前读取：

- Approved PLAN（已批准实施计划）及其所有 Task 的 Dependencies（依赖）与 Validation（验证要求）。
- Current Task State（当前任务状态）。
- 已记录的 Validation Results（验证结果）。
- Risk Gate（风险门禁）与 Human Approval（人工审核）状态。
- Approved PLAN 的 `execution_mode`（执行模式），缺省为 `plan_continuous`。
- Active Approval Record（活跃审批记录） from `.ai/state/approvals/<approval-id>.yaml`.
- Newer Accepted controlling artifacts（更新的已接受控制产物），用于历史 Checkpoint 对账。

按需读取 Router、PLAN 或 IMPL Workflow；不默认加载全部 Roles（角色）、Rules（规则）或 Skills（技能）。

Approved PLAN（已批准计划） defines scope. Active Approval Record（活跃审批记录）
authorizes Runtime to execute inside that scope:

- PLAN 内 Task；
- PLAN 内代码修改；
- PLAN 内测试、Validation（验证）和 Review（审查）；
- PLAN 内 State / Checkpoint（状态 / 检查点）更新；
- PLAN 内必要的普通 bug fix（缺陷修复）；
- PLAN 明确包含的 Documentation Sync（文档同步）。

PLAN Approval（计划批准） must be persisted as an Approval Record. It is not
only a chat message, PLAN prose, Handoff note, or permission for the next Task.
Task Completed（任务完成） is not a Human Gate。

## V2 Runtime Recovery Hook（V2 运行时恢复钩子）

When the user only types “继续”, Orchestrator must apply the Harness V2 Resume Protocol（会话恢复协议） before normal scheduling:

1. Load only the V2 Bootstrap Core Artifacts（启动核心产物） by default: `AGENTS.md`, `.ai/state/execution-state.yaml`, `docs/handoff/HANDOFF-current.md`, selected Workflow（选定工作流）, and the active controlling PRD / ADR / PLAN.
2. Validate the shape of `execution-state.yaml` as Recovery Summary（恢复摘要）.
3. Treat Handoff（交接） as Non-authoritative（非权威摘要）; use it for reading convenience only.
4. Identify the Current Active PLAN（当前活跃计划） and newer Accepted controlling artifacts.
5. Load active Approval Record for the Current Active PLAN.
6. Confirm the Approval Record is active, matches the artifact, and covers the requested action with `scope.allow` and no matching `scope.deny`.
7. Reconcile candidate `RUNNING`, `INTERRUPTED`, `ESCALATED`, `BLOCKED`, and `APPROVAL_REQUIRED` tasks or checkpoints before scheduling.
8. Convert any legacy `RUNNING` task without Active Executor Proof（活跃执行器证明） to `INTERRUPTED`（已中断） only if reconciliation keeps it `ACTIVE`.
9. Prefer exactly one reconciled `ACTIVE` interrupted task over reconciled `READY` tasks and load only that task's per-task Checkpoint（按任务检查点）.
10. If multiple reconciled `ACTIVE` interrupted tasks exist, STOP and ask the user to choose.
11. If no reconciled `ACTIVE` interrupted task exists and reconciled `READY` tasks exist, select the next Task by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）; only then fall back to PLAN order.
12. If the active PLAN is Approved, the Approval Record is active and covers the action, and no Human Gate is active, continue execution instead of asking for PLAN approval again.
13. If no reconciled `ACTIVE` or `READY` task exists and all Current Active PLAN Tasks are `COMPLETE`, set `PLAN_COMPLETE` and produce the Final Report（最终报告）.
14. If only `SUPERSEDED`, `RESOLVED`, or `HISTORICAL` candidates remain, report the reconciliation result and do not resume them.
15. If current `BLOCKED_EXTERNAL` or `APPROVAL_REQUIRED` work remains, STOP and report the blocking terminal state.

Project Context（项目上下文） is resolved from the `project_context` reference in State, **on demand only**. It is not one of the 5 Core Artifacts and does not change the default budget; reading it is an explicit Expand Trigger（扩展触发条件）. Never copy project facts into State, Checkpoint（检查点）, or Handoff（交接）.

Context Budget（上下文预算） is controlled by `max_artifacts`, `max_expansions`, and explicit Expand Triggers（扩展触发条件）. Token percentage is only a Soft Indicator（软指标）. Without State Drift（状态漂移）, missing evidence, or target-path uncertainty, do not expand scanning.

State（状态） cannot redefine PRD / ADR / PLAN / Workflow Exit Gate（退出门禁）. If State, Checkpoint（检查点）, and Current Reality（当前事实） disagree, classify State Drift and STOP for Reconcile（校准） unless the drift is historical and irrelevant to the current task.

Checkpoint State（检查点状态） is not Current Executable State（当前可执行状态）.
Historical Checkpoint Local State（历史检查点本地状态） is evidence only.

## Task State（任务状态）

| State（状态） | 含义 |
|---|---|
| `NOT_STARTED`（未开始） | Task 尚未执行。 |
| `READY`（可执行） | 自身未开始、依赖已完成、风险门禁通过且无需人工批准。 |
| `RUNNING`（执行中） | 当前已有执行上下文，尚未通过 Exit Gate（退出门禁）。 |
| `INTERRUPTED`（已中断） | 执行在正常关闭前停止，必须从 per-task Checkpoint（按任务检查点）和 Reality Anchor（事实锚点）判断 Resume / Rerun。 |
| `BLOCKED`（阻塞） | 依赖未满足，或存在 Environment Blocker（环境阻塞）。 |
| `ESCALATED`（已升级） | 发现 Business / Architecture / Plan / Security 问题，需要返回上游 Workflow 或等待人工审核。 |
| `APPROVAL_REQUIRED`（需要批准） | 当前仍存在 Human Decision（人工决策）且没有后续批准证据。 |
| `COMPLETE`（已完成） | 实现、验证、Review（审查）和 Task Exit Gate 均通过。 |

`BLOCKED` 与 `ESCALATED` 不等价：前者表示当前不能执行，后者表示需要上游决策或人工处理。

## Historical Checkpoint Reconciliation（历史检查点对账）

Before scheduling, reconcile historical checkpoints in this authority order:

1. Newer Accepted Controlling Artifact（更新的已接受控制产物）
2. Top-level Runtime State（顶层运行状态）
3. Current Active PLAN（当前活跃计划）
4. Later Task / Checkpoint Evidence（后续任务 / 检查点证据）
5. Historical Checkpoint Local State（历史检查点本地状态）

Allowed reconciliation statuses:

- `ACTIVE`（活跃）: still belongs to the current active PLAN and remains resumable.
- `SUPERSEDED`（已被取代）: newer Accepted artifact or PLAN replaced the old scope.
- `RESOLVED`（已解决）: later artifact, approval, or completed work resolved the old condition.
- `HISTORICAL`（历史）: evidence only, not current executable work.
- `READY`（可执行）: old blocker is gone and the active PLAN still applies.
- `BLOCKED_EXTERNAL`（外部阻塞）: current external blocker still prevents execution.
- `APPROVAL_REQUIRED`（需要批准）: current decision is still missing.

Only `ACTIVE` and `READY` may enter normal scheduling. `SUPERSEDED`,
`RESOLVED`, and `HISTORICAL` must be reported as reconciliation results and
must not be resumed.

## Scheduling Rules（调度规则）

1. Task Number（任务编号）不等于 Execution Order（执行顺序）。
2. 根据 PLAN 中的 Dependencies 构建 DAG（有向无环依赖图）。
3. `READY` 必须同时满足：
   - 当前状态为 `NOT_STARTED`；
   - 所有直接 Dependencies 状态为 `COMPLETE`；
   - 没有未解决的 Risk Gate；
   - requested action is covered by an active Approval Record（活跃审批记录）；
   - 当前 Task 的 Target、Validation 和 Change Set 仍与 Approved PLAN 一致。
4. `BLOCKED` 或 `ESCALATED` Task 只阻塞依赖它的后续 Task，不阻塞无依赖关系的分支。
5. 若多个 Task 为 `READY`，优先按 Critical Path（关键路径）、Unblocking Power（解阻能力）和 Risk（风险）排序；无法区分时按 PLAN 编号排序。
6. 一次只调度一个 Task 给 IMPL，但默认 Runtime Loop（运行循环）会在该 Task 完成、验证、Checkpoint 和 DAG Recalculation 后自动选择下一个 `READY` Task。
7. `RUNNING` Task 不得再次调度；若没有 Active Executor Proof（活跃执行器证明），先转为 `INTERRUPTED` 并按 Checkpoint（检查点）恢复。
8. 未完成 Required Validation（必需验证）不得转换为 `COMPLETE`。
9. `COMPLETE` Task 默认不加载 Checkpoint；只有 audit、State Drift、缺失证据或用户明确要求时才读取已关闭 Checkpoint。

Default Runtime Loop（默认运行循环）:

```text
PLAN_APPROVED
-> SELECT_READY_TASK
-> TASK_RUNNING
-> VALIDATE
-> CHECKPOINT
-> DAG_RECALCULATE
-> SELECT_READY_TASK
```

If a READY Task exists and no terminal condition exists, Runtime MUST continue
automatically under `plan_continuous`.

Terminal states（终止状态）:

- `PLAN_COMPLETE`（计划完成）
- `APPROVAL_REQUIRED`（需要人工批准）
- `ARCHITECTURE_DRIFT`（架构漂移）
- `SCOPE_EXPANSION`（范围扩张）
- `SECURITY_GATE`（安全门禁）
- `DESTRUCTIVE_ACTION`（破坏性操作）
- `UNRECOVERABLE_FAILURE`（不可恢复失败）

## Drift and Gate Rules（漂移与门禁规则）

- Business Drift（业务漂移）→ STOP → PRD Workflow。
- Architecture Drift（架构漂移）→ STOP → ADR Workflow。
- Plan Drift（计划漂移）→ STOP → PLAN Workflow。
- Security Gate（安全门禁）未通过或需要 Security Exception（安全例外）→ `ESCALATED`，等待人工审核，不得自动批准。
- Environment Blocker（环境阻塞）→ `BLOCKED`，记录证据，不得伪造验证通过。
- Implementation Bug（实现缺陷）留在 IMPL，由当前 Task 修复并重新验证。

Normal Validation Failure（普通验证失败） that can be fixed inside the current
Task and Approved PLAN scope is not a Human Gate. Fix, revalidate, update
Checkpoint / State, recalculate DAG, and continue.

## Human Approval（人工审核）

Human Approval is valid for Runtime only when represented by an active
machine-readable Approval Record. Existing valid approval is not a new Human
Gate.

仅以下事项需要人工审核：

- PRD 业务规则变化；
- ADR 架构、Data Ownership（数据归属）或 System Boundary（系统边界）变化；
- PLAN 范围、依赖或高风险实现变化；
- Breaking Contract Change（破坏性契约语义变化）；
- Security / Privacy Risk（安全 / 隐私风险）或 Security Exception（安全例外）；
- Destructive Action（破坏性操作），例如生产数据删除、不可逆 migration（迁移）或生产破坏性操作；
- External Side Effect（外部副作用），是否 gate 由 policy / profile（策略 / 配置）决定，例如 `git push`、production deploy（生产部署）、public release（公开发布）、registry publish（注册表发布）；
- Unrecoverable Validation Failure（不可恢复验证失败），即无法在 Approved PLAN scope 内合理修复；
- Explicit Human Decision（显式人工决策），即 PLAN 中明确声明 `requires_human_decision: true`；
- PLAN Complete（计划完成）时返回最终执行结果。

普通 IMPL Task 不因调度本身要求人工批准。
Task Completed（任务完成）不得作为 Human Gate。

If the Approval Record has `decision: rejected` or `changes_requested`, Runtime
must not enter IMPL for that artifact. If the record is `superseded`, `revoked`,
`historical`, expired, missing, or denied by scope, classify
`APPROVAL_REQUIRED`.

## Recalculation Procedure（重新计算步骤）

每次重新路由时：

1. 读取 PLAN 的完整 Task 列表和 Dependencies。
2. 记录每个 Task 的当前状态。
3. 先保留 `COMPLETE` 的已确认状态。
4. 对 `RUNNING`、`INTERRUPTED`、`BLOCKED`、`ESCALATED`、`APPROVAL_REQUIRED` 候选执行 Historical Checkpoint Reconciliation。
5. 对 reconciled `ACTIVE` 的 `RUNNING` Task 检查 Active Executor Proof；无证明则转为 `INTERRUPTED`。
6. 对 reconciled `ACTIVE` 的 `INTERRUPTED` Task 使用 per-task Checkpoint 和 Reality Anchor 决定 Resume / Rerun，不得猜测为 `COMPLETE`。
7. 对每个 `NOT_STARTED` Task 检查所有直接依赖。
8. 计算 reconciled `READY`、`ACTIVE` interrupted、`BLOCKED_EXTERNAL`、`APPROVAL_REQUIRED`、`SUPERSEDED`、`RESOLVED` 和 `HISTORICAL` 集合。
9. 沿 DAG 向下传播当前阻塞原因，区分直接阻塞和间接阻塞。
10. 输出可执行集合、对账结果、关键路径阻塞和唯一推荐任务。
11. 若没有 reconciled `ACTIVE` 或 `READY` Task，且所有 Current Active PLAN Task 均为 `COMPLETE`，设置 `PLAN_COMPLETE` 并输出 Final Report（最终报告）。
12. 若没有 reconciled `ACTIVE` 或 `READY` Task，但仍有 `BLOCKED_EXTERNAL` / `APPROVAL_REQUIRED` Task，停止并输出阻塞/升级原因。

## Required Output（必需输出）

每次调度至少输出：

- Task State Table（任务状态表）；
- READY Tasks（可执行任务）；
- INTERRUPTED Tasks（已中断任务）及 Checkpoint path（检查点路径）；
- BLOCKED Tasks（阻塞任务）及直接/间接原因；
- ESCALATED Tasks（升级任务）及待处理事项；
- Critical Path Blockers（关键路径阻塞）；
- Reconciliation Results（对账结果） and authority source（权威来源）；
- Approval Record Status（审批记录状态） and scope decision（范围判定）；
- Recommended Next Task（推荐下一任务）或 `PLAN_COMPLETE`；
- Human Approval Required（是否需要人工审核）。

必须使用 English Term（中文解释），关键结论必须有中文。

## Dry Run（演练）

以下为**项目无关**的调度演练；任务编号与名称仅为示例，不构成对任何具体项目的依赖。

输入状态：

- Task A、Task B、Task C = `COMPLETE`；
- Task D = `ESCALATED`（安全门禁未通过）；
- Task E = `BLOCKED`（依赖 Task D）；
- Task F = `NOT_STARTED`，且唯一依赖 Task C 已 `COMPLETE`。

计算结果：

- Task D 保持 `ESCALATED`，只阻塞依赖 Task D 的后续任务；
- Task E 保持 `BLOCKED`，只阻塞依赖 Task E 的后续任务；
- Task F 满足 `READY` 条件；
- 推荐 Task F；
- 在 `plan_continuous` 下执行权将交给 IMPL，Task F 完成后继续重新计算 DAG；
- Human Approval Required（人工审核）：当前调度不需要，但 Task D 的安全升级仍需后续人工/PLAN 处理。

## Exit Rule（退出规则）

Orchestrator 只完成调度和报告。选定 `READY` Task 后，将执行权交给对应 Workflow。

In default `plan_continuous` mode, the Runtime returns to Orchestrator after
each Task's Validation / Checkpoint / DAG Recalculation and continues with the
next READY Task without asking Human Approval again.

In explicit `task_gated` compatibility mode, Orchestrator may stop after one
Task and wait for explicit continuation.
