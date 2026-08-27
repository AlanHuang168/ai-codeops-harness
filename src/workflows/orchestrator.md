# Task Orchestrator Workflow

## Purpose（目的）

Task Orchestrator（任务编排器）只负责根据 Approved PLAN（已批准实施计划）调度 Atomic Task（原子任务）。

它不修改 PRD、ADR、PLAN 或业务代码，也不替代 Router、PLAN 或 IMPL Workflow。

## Inputs（输入）

调度前读取：

- Approved PLAN（已批准实施计划）及其所有 Task 的 Dependencies（依赖）与 Validation（验证要求）。
- Current Task State（当前任务状态）。
- 已记录的 Validation Results（验证结果）。
- Risk Gate（风险门禁）与 Human Approval（人工审核）状态。

按需读取 Router、PLAN 或 IMPL Workflow；不默认加载全部 Roles（角色）、Rules（规则）或 Skills（技能）。

## V2 Runtime Recovery Hook（V2 运行时恢复钩子）

When the user only types “继续”, Orchestrator must apply the Harness V2 Resume Protocol（会话恢复协议） before normal scheduling:

1. Load only the V2 Bootstrap Core Artifacts（启动核心产物） by default: `AGENTS.md`, `.ai/state/execution-state.yaml`, `docs/handoff/HANDOFF-current.md`, selected Workflow（选定工作流）, and the active controlling PRD / ADR / PLAN.
2. Validate the shape of `execution-state.yaml` as Recovery Summary（恢复摘要）.
3. Treat Handoff（交接） as Non-authoritative（非权威摘要）; use it for reading convenience only.
4. Convert any legacy `RUNNING` task without Active Executor Proof（活跃执行器证明） to `INTERRUPTED`（已中断） before scheduling.
5. Prefer exactly one `INTERRUPTED` task over any `READY` task and load only that task's per-task Checkpoint（按任务检查点）.
6. If multiple `INTERRUPTED` tasks exist, STOP and ask the user to choose.
7. If no `INTERRUPTED` task exists and exactly one `READY` task exists, select that task.
8. If multiple `READY` tasks exist, choose by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）; only then fall back to PLAN order.
9. If no `INTERRUPTED` or `READY` task exists, STOP and report that there is nothing to continue.

Project Context（项目上下文） is resolved from the `project_context` reference in State, **on demand only**. It is not one of the 5 Core Artifacts and does not change the default budget; reading it is an explicit Expand Trigger（扩展触发条件）. Never copy project facts into State, Checkpoint（检查点）, or Handoff（交接）.

Context Budget（上下文预算） is controlled by `max_artifacts`, `max_expansions`, and explicit Expand Triggers（扩展触发条件）. Token percentage is only a Soft Indicator（软指标）. Without State Drift（状态漂移）, missing evidence, or target-path uncertainty, do not expand scanning.

State（状态） cannot redefine PRD / ADR / PLAN / Workflow Exit Gate（退出门禁）. If State, Checkpoint（检查点）, and Current Reality（当前事实） disagree, classify State Drift and STOP for Reconcile（校准） unless the drift is historical and irrelevant to the current task.

## Task State（任务状态）

| State（状态） | 含义 |
|---|---|
| `NOT_STARTED`（未开始） | Task 尚未执行。 |
| `READY`（可执行） | 自身未开始、依赖已完成、风险门禁通过且无需人工批准。 |
| `RUNNING`（执行中） | 当前已有执行上下文，尚未通过 Exit Gate（退出门禁）。 |
| `INTERRUPTED`（已中断） | 执行在正常关闭前停止，必须从 per-task Checkpoint（按任务检查点）和 Reality Anchor（事实锚点）判断 Resume / Rerun。 |
| `BLOCKED`（阻塞） | 依赖未满足，或存在 Environment Blocker（环境阻塞）。 |
| `ESCALATED`（已升级） | 发现 Business / Architecture / Plan / Security 问题，需要返回上游 Workflow 或等待人工审核。 |
| `COMPLETE`（已完成） | 实现、验证、Review（审查）和 Task Exit Gate 均通过。 |

`BLOCKED` 与 `ESCALATED` 不等价：前者表示当前不能执行，后者表示需要上游决策或人工处理。

## Scheduling Rules（调度规则）

1. Task Number（任务编号）不等于 Execution Order（执行顺序）。
2. 根据 PLAN 中的 Dependencies 构建 DAG（有向无环依赖图）。
3. `READY` 必须同时满足：
   - 当前状态为 `NOT_STARTED`；
   - 所有直接 Dependencies 状态为 `COMPLETE`；
   - 没有未解决的 Risk Gate；
   - 没有必须人工批准的事项；
   - 当前 Task 的 Target、Validation 和 Change Set 仍与 Approved PLAN 一致。
4. `BLOCKED` 或 `ESCALATED` Task 只阻塞依赖它的后续 Task，不阻塞无依赖关系的分支。
5. 若多个 Task 为 `READY`，优先按 Critical Path（关键路径）、Unblocking Power（解阻能力）和 Risk（风险）排序；无法区分时按 PLAN 编号排序。
6. 一次只调度一个 Task。调度器不自动执行实现。
7. `RUNNING` Task 不得再次调度；若没有 Active Executor Proof（活跃执行器证明），先转为 `INTERRUPTED` 并按 Checkpoint（检查点）恢复。
8. 未完成 Required Validation（必需验证）不得转换为 `COMPLETE`。
9. `COMPLETE` Task 默认不加载 Checkpoint；只有 audit、State Drift、缺失证据或用户明确要求时才读取已关闭 Checkpoint。

## Drift and Gate Rules（漂移与门禁规则）

- Business Drift（业务漂移）→ STOP → PRD Workflow。
- Architecture Drift（架构漂移）→ STOP → ADR Workflow。
- Plan Drift（计划漂移）→ STOP → PLAN Workflow。
- Security Gate（安全门禁）未通过或需要 Security Exception（安全例外）→ `ESCALATED`，等待人工审核，不得自动批准。
- Environment Blocker（环境阻塞）→ `BLOCKED`，记录证据，不得伪造验证通过。
- Implementation Bug（实现缺陷）留在 IMPL，由当前 Task 修复并重新验证。

## Human Approval（人工审核）

仅以下事项需要人工审核：

- PRD 业务规则变化；
- ADR 架构、Data Ownership（数据归属）或 System Boundary（系统边界）变化；
- PLAN 范围、依赖或高风险实现变化；
- Security Exception（安全例外）。

普通 IMPL Task 不因调度本身要求人工批准。

## Recalculation Procedure（重新计算步骤）

每次重新路由时：

1. 读取 PLAN 的完整 Task 列表和 Dependencies。
2. 记录每个 Task 的当前状态。
3. 先保留 `COMPLETE`、`RUNNING`、`BLOCKED`、`ESCALATED` 的已确认状态。
4. 对 `RUNNING` Task 检查 Active Executor Proof；无证明则转为 `INTERRUPTED`。
5. 对 `INTERRUPTED` Task 使用 per-task Checkpoint 和 Reality Anchor 决定 Resume / Rerun，不得猜测为 `COMPLETE`。
6. 对每个 `NOT_STARTED` Task 检查所有直接依赖。
7. 计算 `READY`、`INTERRUPTED`、`BLOCKED` 和 `ESCALATED` 集合。
8. 沿 DAG 向下传播阻塞原因，区分直接阻塞和间接阻塞。
9. 输出可执行集合、关键路径阻塞和唯一推荐任务。
10. 若没有 `INTERRUPTED` 或 `READY` Task，停止并输出阻塞/升级原因。

## Required Output（必需输出）

每次调度至少输出：

- Task State Table（任务状态表）；
- READY Tasks（可执行任务）；
- INTERRUPTED Tasks（已中断任务）及 Checkpoint path（检查点路径）；
- BLOCKED Tasks（阻塞任务）及直接/间接原因；
- ESCALATED Tasks（升级任务）及待处理事项；
- Critical Path Blockers（关键路径阻塞）；
- Recommended Next Task（推荐下一任务）；
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
- 本次 Dry Run 不执行 Task F；
- Human Approval Required（人工审核）：当前调度不需要，但 Task D 的安全升级仍需后续人工/PLAN 处理。

## Exit Rule（退出规则）

Orchestrator 只完成调度和报告。选定 `READY` Task 后，将执行权交给对应 Workflow；不得在同一轮自动进入 IMPL 或执行下一个 Task。
