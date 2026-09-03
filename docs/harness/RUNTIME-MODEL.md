# AI CodeOps Harness Runtime Model

- Status: Active
- Scope: Project-scoped AI Engineering Runtime（项目级 AI 工程运行时）
- Authority: Harness Protocol（Harness 协议规范）

## Purpose

This document defines what the AI CodeOps Harness Runtime is, where it runs,
how it routes work, how it loads context, and how it recovers across sessions.
It describes the current implementation and protocol surface. It does not
define a resident Runtime Engine, a model host, or a background service.

## Runtime Evidence

The current source provides the following evidence:

| Evidence | What it proves | Status |
| --- | --- | --- |
| adapters/shared/AGENTS.md | Common Bootstrap, routing, progressive disclosure, and V2 recovery rules | IMPLEMENTED Harness entry contract |
| adapters/claude/CLAUDE.md | Claude Code entry adapter and Bootstrap forwarding | IMPLEMENTED adapter contract |
| src/workflows/router.md | Workflow selection, re-entry, escalation, and routing output | PROTOCOL-DEFINED |
| src/workflows/risk-router.md | Change Risk classification and Fast / Standard / Architecture path mapping | PROTOCOL-DEFINED |
| src/rules/eval.md | TEST vs EVAL separation, Eval Contract, and regression dataset obligation | PROTOCOL-DEFINED |
| src/rules/release.md | Release / Deployment Definition of Done and Release Gate | PROTOCOL-DEFINED |
| src/workflows/*.md | PRD, ADR, PLAN, IMPL, and Orchestrator workflow instructions | PROTOCOL-DEFINED |
| src/rules/*.md | Generic engineering constraints loaded by task need | PROTOCOL-DEFINED |
| src/roles/*.md | Role guidance loaded by task need | PROTOCOL-DEFINED |
| docs/harness/HARNESS-V2.md | State, Checkpoint, Resume, Handoff, and context-budget protocol | PROTOCOL-DEFINED |
| docs/harness/PROJECT-CONTEXT-CONTRACT.md | Project Context boundary and required portable shape | PROTOCOL-DEFINED |
| docs/harness/HARNESS-TEMPLATE-BOUNDARY.md | Source/runtime boundary and adoption constraints | PROTOCOL-DEFINED |
| Resident process, database, or runtime service | None in the current repository | NOT IMPLEMENTED |

The AI Coding Tool executes the work. The Harness supplies the entry
conventions, governance, context rules, workflow instructions, and recovery
artifacts that the tool reads and updates.

## Runtime Definition

AI CodeOps Harness is a **Project-scoped AI Engineering Runtime**.

It is not a resident process-style Agent Runtime. It is activated inside an
adopting project by an AI Coding Tool and operates through project files and
protocols:

- **Entry**: an AI Tool Adapter provides the stable tool-specific entry point.
- **Routing**: the Router selects the latest safe Workflow stage.
- **Context**: Authority and Progressive Disclosure determine what to load.
- **Workflow**: the selected workflow guides the task execution.
- **State / Recovery**: State, per-task Checkpoints, and Handoff preserve the
  facts needed to continue.
- **Governance**: Rules, Roles, PRD, ADR, PLAN, and validation gates constrain
  what may be changed.

Accepted PLAN（已接受计划） is the Runtime Unit（运行单元） and Authorization
Unit（授权单元）. Task（任务） is the Execution Unit（执行单元）. Human Gate
（人工门禁） is the Decision Unit（决策单元）.

Human-in-the-loop（人在回路） means Human owns key decisions, not every normal
execution step. Human Approval（人工审批） is a persisted Runtime Fact（运行事实）.
An active Approval Record（审批记录） authorizes Runtime to execute approved
in-scope Tasks, validation, checkpointing, state updates, and ordinary
in-scope fixes until PLAN completion or a real Human Gate.

Artifact（产物） defines what may be done. Approval Record defines whether Human
authorized executing that artifact. Approval cannot expand artifact scope.

The installed representation is:

~~~text
.ai/**       Installed Runtime（安装后运行时）
src/**       Authoring Source（编写源码）
adapters/**  AI Tool Adapter Source（AI 工具适配器源码）
~~~

The source repository does not become the target project. The Installer maps
src/** to .ai/** and generates the selected adapter entry files in the target
project.

## Runtime Layers

~~~text
Harness Runtime
│
├── Entry Runtime
│   └── Adapter → Bootstrap
│
├── Routing Runtime
│   └── Router → Workflow Selection
│
├── Context Runtime
│   └── Authority + Progressive Disclosure
│
└── State Runtime
    └── Approval + Checkpoint + Resume + Handoff
~~~

These are runtime responsibilities, not four resident processes:

| Layer | Responsibility | Current status |
| --- | --- | --- |
| Entry Runtime | Start from Codex or Claude Code and enter the Harness contract | IMPLEMENTED adapter files; execution is performed by the AI tool |
| Routing Runtime | Select PRD, ADR, PLAN, or IMPL and escalate on drift | PROTOCOL-DEFINED by Router and Orchestrator workflows |
| Context Runtime | Apply authority order and load only required context | PROTOCOL-DEFINED; no separate context server |
| State Runtime | Record recovery facts, Approval Records, and per-task Checkpoints | PROTOCOL-DEFINED; file artifacts are the runtime boundary |

## Runtime Lifecycle

~~~mermaid
flowchart TD
    A[AI Coding Tool] --> B[Adapter]
    B --> C[Bootstrap]
    C --> D[Router]
    D --> E{Resume?}
    E -- YES --> F[Checkpoint]
    E -- NO --> G[New Workflow]
    F --> H[Context Loading]
    G --> H
    H --> I[Workflow Execution]
    I --> J[Verification]
    J --> K[Checkpoint]
    K --> N[DAG Recalculation]
    N --> O{READY Task?}
    O -- YES, no Human Gate --> H
    O -- NO --> L[Handoff / Final Report]
    L --> M[Next Session]
    M --> E
~~~

Resume? is a decision against Runtime Facts and Current Reality. An
INTERRUPTED or RUNNING task is not assumed to be complete. A legacy RUNNING
task without Active Executor Proof is converted to INTERRUPTED before
recovery. A closed Checkpoint for a COMPLETE task is not loaded by default.
Historical checkpoint local state is not current executable state. Before any
old `INTERRUPTED`, `ESCALATED`, `BLOCKED`, or `APPROVAL_REQUIRED` checkpoint is
resumed, the Runtime reconciles it against newer accepted artifacts, top-level
state, the current active PLAN, and later task/checkpoint evidence.
If an Approved PLAN and active matching Approval Record already exist, the
record is still valid, the requested action is in scope, and no Human Gate is
active, recovery must continue from the interrupted or next READY Task without
asking for PLAN approval again.

Default Runtime Execution Loop（默认运行循环）:

~~~text
PLAN_APPROVED
-> SELECT_READY_TASK
-> TASK_RUNNING
-> VALIDATE
-> CHECKPOINT
-> DAG_RECALCULATE
-> SELECT_READY_TASK
~~~

Terminal states（终止状态）:

- `PLAN_COMPLETE`（计划完成）
- `APPROVAL_REQUIRED`（需要人工批准）
- `ARCHITECTURE_DRIFT`（架构漂移）
- `SCOPE_EXPANSION`（范围扩张）
- `SECURITY_GATE`（安全门禁）
- `DESTRUCTIVE_ACTION`（破坏性操作）
- `RELEASE_GATE`（发布门禁）
- `UNRECOVERABLE_FAILURE`（不可恢复失败）

Task completion is not a Human Gate. `RELEASE_GATE` is the release / deploy /
publish specialization of the External Side Effect gate and always requires
Human authorization regardless of Risk Tier.

## Progressive Disclosure

The Runtime must not load the entire Harness at startup. Loading every rule,
role, workflow, and project document creates unrelated context and makes
conflicts harder to identify.

~~~text
Task
 ↓
Router
 ↓
Determine Required Context
 ↓
Load Required Rules
Load Required Role
Load Required Workflow
Load Relevant Project Context
 ↓
Execute
~~~

Progressive Disclosure（渐进式披露） aims to:

- reduce unrelated context;
- reduce Rule Collision（规则冲突）;
- control the Context Window（上下文窗口）; and
- keep the task focused.

The default V2 Bootstrap reads at most five Core Artifacts. Project Context is
resolved on demand and is an explicit expansion trigger. Context Budget is
primarily controlled by max_artifacts, max_expansions, and explicit expansion
triggers; token percentages are only soft indicators.

It is a loading policy and optimization mechanism, not a guaranteed percentage
of token savings.

## State and Recovery Model

### Checkpoint

Checkpoint（检查点） is a per-task Runtime Fact. It records the minimum
structured facts needed to resume or rerun a task, including progress phase,
pending steps, changed paths, validation status, and a Reality Anchor（事实锚点）.
Each task has its own file:

~~~text
.ai/state/checkpoints/tasks/<task-id>.yaml
~~~

Checkpoint lifecycle:

~~~text
CREATED → UPDATED → VALIDATED → CLOSED / INTERRUPTED
~~~

### Approval

Approval Record（审批记录） is a machine-readable Runtime Fact for Human
Decision（人工决策）. It is stored under:

~~~text
.ai/state/approvals/<approval-id>.yaml
~~~

Top-level State references active approval ids, but the record itself carries
the artifact, decision, status, scope allow/deny lists, provenance, expiration,
and supersession fields. Conversation approval without a persisted record is
not reliable recovery evidence.

Approval Recovery Authority（审批恢复权威）:

1. Accepted Controlling Artifact（已接受控制产物）
2. Active Machine-Readable Approval Record（活跃机器可读审批记录）
3. Top-level Runtime State（顶层运行状态）
4. Checkpoint Evidence（检查点证据）
5. Handoff（交接）
6. Conversation Context（对话上下文）

### Resume

Resume Protocol（恢复协议） is the decision procedure used at Bootstrap and
by the Orchestrator. It reads authoritative Runtime Facts and Current Reality,
loads the matching active Approval Record, reconciles historical checkpoints,
then prefers reconciled ACTIVE interrupted tasks, followed by reconciled READY
tasks. Multiple active interrupted tasks require a choice; multiple ready tasks
are ordered by Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk
（风险）. Under the default `plan_continuous` mode, selecting a READY task
continues the Approved PLAN execution when Approval Record scope covers the
requested action; it does not create a new Human Approval boundary.

Historical Checkpoint Reconciliation（历史检查点对账） authority order:

1. Newer Accepted Controlling Artifact（更新的已接受控制产物）
2. Top-level Runtime State（顶层运行状态）
3. Current Active PLAN（当前活跃计划）
4. Later Task / Checkpoint Evidence（后续任务 / 检查点证据）
5. Historical Checkpoint Local State（历史检查点本地状态）

Reconciliation can classify a checkpoint as `ACTIVE`, `SUPERSEDED`,
`RESOLVED`, `HISTORICAL`, `READY`, `BLOCKED_EXTERNAL`, or `APPROVAL_REQUIRED`.
Only `ACTIVE` and `READY` are executable.

### Handoff

Handoff（交接） is a human- and AI-readable summary. It is
Non-authoritative（非权威） and cannot override State, Checkpoint, Governance
Rules, Accepted decisions, or Current Reality. Detailed validation logs belong
in task reports or validation artifacts, not in the minimal execution State.

### Cross-session example

~~~text
Session A
→ Execute
→ Checkpoint
→ Handoff

Session B
→ Bootstrap
→ Resume
→ Restore Context
→ Continue
~~~

No database, Redis instance, or background Runtime Service is required by this
model. Runtime Facts are project files under .ai/state/, while Handoff is a
human-facing project document.

## Authority and Context Boundaries

Governance Rules define what may happen. Runtime Facts record what happened or
where execution stopped. State cannot weaken an Approved PLAN Exit Gate, and a
Handoff cannot replace an Accepted ADR.

~~~text
Harness Core      → AGENTS.md + .ai/
Harness Protocol  → docs/harness/
Project Context   → docs/project/
Runtime State     → .ai/state/
AI Adapter        → adapters/**, installed as tool entry files
~~~

The Runtime resolves Project Context only when the task needs project facts,
boundaries, terminology, or conventions. It does not copy those facts into
State, Checkpoint, Handoff, or the adapter file.

## Harness vs Traditional Agent Runtime

| AI CodeOps Harness | Traditional Agent Runtime |
| --- | --- |
| Project-scoped | Service/process-scoped |
| AI Coding Tool executes | Runtime Engine executes |
| File/protocol driven | Code/graph driven |
| .ai/** runtime | Runtime service |
| Governance + context | Model/tool orchestration |
| No model hosting | Often manages model calls |

The Harness does not replace LangGraph or another Agent Runtime. It addresses
AI Coding Engineering Governance: how an AI coding tool enters a project,
selects work, loads context, respects decisions, records recovery facts, and
continues safely.

## SDD / TDD Position

SDD / TDD / SDD+TDD belong in the Workflow Layer:

~~~text
SDD / TDD / SDD+TDD → Development Workflow
~~~

- SDD = Spec-Driven Development（规格驱动开发）.
- TDD = Test-Driven Development（测试驱动开发）.

The current repository has no formal sdd.md or tdd.md workflow. These are
**Planned** capabilities, not implemented Runtime layers.

## Runtime Model Status Matrix

| Capability | Status | Evidence / boundary |
| --- | --- | --- |
| Codex and Claude Code adapter entry | IMPLEMENTED | adapters/ source files |
| Bootstrap and Router instructions | PROTOCOL-DEFINED | Adapter and src/workflows/router.md |
| Change Risk Router and Risk Tiers | PROTOCOL-DEFINED | src/workflows/risk-router.md |
| TEST / EVAL separation and Acceptance Contract | PROTOCOL-DEFINED | src/rules/eval.md, src/workflows/plan.md, src/workflows/impl.md |
| Release / Deployment Definition of Done | PROTOCOL-DEFINED | src/rules/release.md |
| PRD / ADR / PLAN / IMPL workflows | PROTOCOL-DEFINED | src/workflows/ |
| Rules and Roles | PROTOCOL-DEFINED | src/rules/, src/roles/ |
| Authority and Progressive Disclosure | PROTOCOL-DEFINED | Adapter, Router, and V2 protocol |
| State / Approval Record / Checkpoint / Resume / Handoff | PROTOCOL-DEFINED | HARNESS-V2.md and runtime file boundary |
| Resident Runtime Engine | NOT IMPLEMENTED | No process or service in repository |
| Database-backed runtime state | NOT IMPLEMENTED | No database or state service |
| SDD / TDD workflows | PLANNED | No formal sdd.md / tdd.md |
| Additional tool adapters | PLANNED | Registry entries only where marked planned |

## Runtime Lifecycle Diagram Specification

This is a visual design brief for a future README image. It does not generate
an image or add a new runtime capability.

### Composition

Use a left-to-right or top-to-bottom flow with seven visual groups:

1. **Entry**: Adapter → Bootstrap.
2. **Decision**: Router with a clearly visible Resume return path.
3. **Context**: Context Runtime as the controlled loading stage.
4. **Execution**: Workflow → Verify.
5. **Continuation**: Checkpoint → DAG Recalculation loops back to the next
   READY Task while the PLAN approval still covers it.
6. **Recovery**: Checkpoint loops back to Resume.
7. **Handoff**: Handoff leads to the next session.

### Core visual flow

~~~text
Adapter
   ↓
Bootstrap
   ↓
Router ←──────── Resume
   ↓               ↑
Context Runtime    │
   ↓               │
Workflow           │
   ↓               │
Verify             │
   ↓               │
Checkpoint ────────┘
   ↓
DAG Recalculation ──→ next READY Task (back to Context Runtime)
   ↓
Handoff / Final Report
~~~

### Visual constraints

- Show the AI Coding Tool outside the Harness boundary as the executor.
- Use a distinct boundary around Harness Runtime responsibilities.
- Use a loop arrow for recovery, not a linear “completion” arrow.
- Show continuous PLAN execution as a loop back to the next READY Task, not as
  a Human Approval step after every Task.
- Label Context Loading as selective, not exhaustive.
- Mark SDD/TDD and future adapters as Planned if shown.
- Keep .ai/** as the installed runtime label and src/** as the authoring source label.
- Do not depict a daemon, database, model host, or hidden orchestration service.
