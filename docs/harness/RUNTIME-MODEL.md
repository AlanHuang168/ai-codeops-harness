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
| adapters/codex/AGENTS.md | Tool entry, Bootstrap, routing, progressive disclosure, and V2 recovery rules | IMPLEMENTED adapter contract |
| adapters/claude/CLAUDE.md | Claude Code entry adapter and Bootstrap forwarding | IMPLEMENTED adapter contract |
| src/workflows/router.md | Workflow selection, re-entry, escalation, and routing output | PROTOCOL-DEFINED |
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
    └── Checkpoint + Resume + Handoff
~~~

These are runtime responsibilities, not four resident processes:

| Layer | Responsibility | Current status |
| --- | --- | --- |
| Entry Runtime | Start from Codex or Claude Code and enter the Harness contract | IMPLEMENTED adapter files; execution is performed by the AI tool |
| Routing Runtime | Select PRD, ADR, PLAN, or IMPL and escalate on drift | PROTOCOL-DEFINED by Router and Orchestrator workflows |
| Context Runtime | Apply authority order and load only required context | PROTOCOL-DEFINED; no separate context server |
| State Runtime | Record recovery facts and resume from per-task Checkpoints | PROTOCOL-DEFINED; file artifacts are the runtime boundary |

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
    K --> L[Handoff]
    L --> M[Next Session]
    M --> E
~~~

Resume? is a decision against Runtime Facts and Current Reality. An
INTERRUPTED or RUNNING task is not assumed to be complete. A legacy RUNNING
task without Active Executor Proof is converted to INTERRUPTED before
recovery. A closed Checkpoint for a COMPLETE task is not loaded by default.

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

### Resume

Resume Protocol（恢复协议） is the decision procedure used at Bootstrap and
by the Orchestrator. It reads authoritative Runtime Facts and Current Reality,
then prefers INTERRUPTED tasks, followed by a unique READY task. Multiple
interrupted tasks require a choice; multiple ready tasks are ordered by
Critical Path（关键路径）, Unblocking Power（解阻能力）, and Risk（风险）.

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
| PRD / ADR / PLAN / IMPL workflows | PROTOCOL-DEFINED | src/workflows/ |
| Rules and Roles | PROTOCOL-DEFINED | src/rules/, src/roles/ |
| Authority and Progressive Disclosure | PROTOCOL-DEFINED | Adapter, Router, and V2 protocol |
| State / Checkpoint / Resume / Handoff | PROTOCOL-DEFINED | HARNESS-V2.md and runtime file boundary |
| Resident Runtime Engine | NOT IMPLEMENTED | No process or service in repository |
| Database-backed runtime state | NOT IMPLEMENTED | No database or state service |
| SDD / TDD workflows | PLANNED | No formal sdd.md / tdd.md |
| Additional tool adapters | PLANNED | Registry entries only where marked planned |

## Runtime Lifecycle Diagram Specification

This is a visual design brief for a future README image. It does not generate
an image or add a new runtime capability.

### Composition

Use a left-to-right or top-to-bottom flow with six visual groups:

1. **Entry**: Adapter → Bootstrap.
2. **Decision**: Router with a clearly visible Resume return path.
3. **Context**: Context Runtime as the controlled loading stage.
4. **Execution**: Workflow → Verify.
5. **Recovery**: Checkpoint loops back to Resume.
6. **Handoff**: Handoff leads to the next session.

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
Handoff
~~~

### Visual constraints

- Show the AI Coding Tool outside the Harness boundary as the executor.
- Use a distinct boundary around Harness Runtime responsibilities.
- Use a loop arrow for recovery, not a linear “completion” arrow.
- Label Context Loading as selective, not exhaustive.
- Mark SDD/TDD and future adapters as Planned if shown.
- Keep .ai/** as the installed runtime label and src/** as the authoring source label.
- Do not depict a daemon, database, model host, or hidden orchestration service.

