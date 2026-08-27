# Handoff Contract（交接契约）

Handoff（交接） documents are human-readable summaries for Cross-AI Handoff（跨 AI 交接） and cross-session recovery. They are intentionally Non-authoritative（非权威摘要）.

Authoritative recovery facts remain in:

- `.ai/state/execution-state.yaml` for State Recovery Summary（状态恢复摘要）.
- `.ai/state/checkpoints/tasks/<task-id>.yaml` for per-task Checkpoint（按任务检查点） facts.
- Current Reality Check（当前事实检查） evidence for implementation truth.
- Governance Rules（治理规则）: PRD, ADR, PLAN, Workflow, and project rules.

Handoff must not override State（状态）, Checkpoint（检查点）, Governance Rules（治理规则）, or Current Reality（当前事实）. If Handoff disagrees with those sources, treat it as a State Drift（状态漂移） or Handoff Drift（交接漂移） signal and reconcile before continuing.

## Required Content（必需内容）

Each active handoff should keep a concise summary of:

- Active Artifacts（活跃产物）: PRD / ADR / PLAN ids and paths.
- Current Task State（当前任务状态）: READY, RUNNING, INTERRUPTED, BLOCKED, ESCALATED, COMPLETE.
- Recommended Next Action（推荐下一步） and the reason.
- Changed Paths（已变更路径） relevant to the current handoff.
- Validation Evidence（验证证据） with Evidence Kind（证据类型）.
- Known Drift（已知漂移）, Blockers（阻塞）, Escalations（升级）, and Human Gates（人工门禁）.
- Recovery Rule（恢复规则） reminding the next agent to trust Current Reality and State before Handoff.

Use English Term（中文解释） for human-facing conclusions.

## Validation Evidence（验证证据）

Allowed Evidence Kind（证据类型）:

- Executed Test（已执行测试）
- Human Validation（人工验证）
- Code-path Review（代码路径审查）
- NOT RUN（未执行）

Code-path Review（代码路径审查） is not Executed Test（已执行测试）. NOT RUN（未执行） must not be inferred as PASS（通过）.

## Forbidden Content（禁止内容）

Never write these into handoff documents:

- Secrets, tokens, cookies, passwords, or API keys.
- Database connection values or `.env` content.
- Raw PII（原始个人信息） or production account data.
- Full command output when a short result summary is enough.
- Long chat-history transcripts as the only recovery source.

## Update Timing（更新时机）

Update Handoff after task validation and before STOP（停止） when an Atomic Task（原子任务） changes recovery-relevant facts.

For Harness V2 tasks, follow:

```text
Implementation -> Validation -> Checkpoint/State Update -> DAG Recalculation -> STOP
```

Handoff may summarize the result, but the next agent must resume from `execution-state.yaml` and any required task checkpoint, not from this file alone.
