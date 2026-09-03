# ADR Workflow

## Purpose

Turn already-clear product requirements into stable, traceable architecture decisions,
and keep architecture documentation consistent with the real system.

An ADR answers:

- What the current real architecture is
- Which architecture problems need a decision
- What viable options exist
- Why the current option was chosen
- What impact the decision brings

## Triggers

Enter ADR when any of:

- Adding, removing, or merging a subsystem
- System responsibility or boundary change
- Data Owner change
- Database boundary or Schema ownership change
- Significant API / Event Contract change
- External Provider / Webhook integration change
- Sync / async model change
- Authentication or authorization model change
- Introducing significant infrastructure or dependency
- Current implementation is inconsistent with an existing ADR or with Project Context
- The PRD contains a problem needing an architecture decision

> Project Context（项目上下文）resolves from the `project_context` reference in Runtime State; see the Project Context Resolution rule in `AGENTS.md`. Read it on demand only.

Ordinary UI changes, local bugs, and implementation details with no architectural impact usually need no ADR.

## Process

### 1. Context

Read only what the current task needs:

- PRD
- Project Context
- AGENTS.md
- Related ADRs
- Target subsystem docs
- Related code
- Schema / Contract
- Actual deployment info

Follow Progressive Disclosure;
do not read the whole workspace without purpose.

### 2. Current Reality

Confirm the real implementation first.

Check:

- Current system responsibilities
- Current call relationships
- Current Data Owner
- Current database structure
- Current Provider / Adapter
- Current API / Event
- Current deployment

Documentation cannot replace evidence of the real implementation.

### 3. Drift Detection

Compare:

Current Implementation
vs
Project Context
vs
Existing ADR
vs
PRD

Record Architecture Drift explicitly when an inconsistency appears.

Do not force-restore an old architecture just to match old docs.

### 4. Decision Problem

State the architecture problem that actually needs solving.

An ADR should ideally resolve only one main decision.

### 5. Options

Analyze at least the genuinely viable options.

For each option consider:

- Benefits
- Costs
- Complexity
- Coupling
- Data Ownership
- Security
- Operability
- Future Impact

Do not invent meaningless options for form's sake.

### 6. Decision

State:

- Selected Option
- Decision Reason
- Rejected Options
- Trade-offs

Prefer:

- Simple
- Clear boundaries
- Verifiable
- Matched to the current scale
- Least unnecessary abstraction

### 7. Consequences

Record:

Positive
- What is gained

Negative
- What is paid

Risks
- What could go wrong

Follow-up
- What must be handled later

### 8. ADR Lifecycle

ADR status must at least support:

- Proposed
- Accepted
- Superseded
- Deprecated

When Human accepts an ADR, persist that Human Decision（人工决策） as an
Approval Record（审批记录） under `.ai/state/approvals/` when Harness V2 Runtime
State is available. ADR status alone is not sufficient for reliable
cross-session approval recovery.

When an existing decision is replaced:

Do not delete the historical ADR.

Create a new ADR or state the relationship explicitly:

Supersedes: ADR-xxxx

Mark the old ADR:

Superseded by ADR-yyyy

### 9. Context Sync

After the ADR is Accepted, check and sync:

- Project Context
- contracts/
- Subsystem README / AGENTS.md
- Other affected architecture docs
- Runtime State approval reference, when state updates are allowed

Update only affected content.

### 10. Architecture Fitness Functions（架构适应度函数）

An Accepted ADR should, when practical, produce one or more **Architecture
Fitness Functions（架构适应度函数）**: verifiable constraints that keep the
decision from silently eroding over time.

A fitness function turns an architecture decision into a repeatable check, the
same way EVAL turns a business requirement into a measurable one. Examples of a
constraint（约束）: "module A must not import module B", "external calls go only
through the adapter boundary", "P95 latency < target". The harness defines the
**shape**; the concrete constraint and its command are project inputs, resolved
on demand like Project Context.

```yaml
fitness_functions:
  - id: AFF-<ADR-id>-<n>
    constraint: <verifiable architecture constraint>
    measurement: <command / tool / check that verifies it>
    result: <PASS | FAIL | NOT_RUN | BLOCKED>
```

Rules:

- Fitness functions are **optional**; an ADR without them is still valid, and
  legacy ADRs are not required to backfill them.
- A fitness function shares the EVAL result enum and evidence rules（see
  `eval.md`）. `NOT_RUN` must not be reported as `PASS`.
- A `FAIL` fitness function is an executable signal of Architecture Drift
  （架构漂移）: IMPL routes it to `ARCHITECTURE_DRIFT` / `APPROVAL_REQUIRED`,
  not a silent in-scope fix.
- Do not embed a specific project's constraints or commands into the harness.

## ADR Output

At minimum:

1. Title
2. Status
3. Context
4. Current Reality
5. Decision Problem
6. Options
7. Decision
8. Consequences
9. Risks
10. Supersedes / Related ADR
11. Documentation Impact
12. Architecture Fitness Functions（架构适应度函数），when practical, else `N/A`

## Forbidden

In the ADR stage:

- Making an architecture decision without checking the real implementation
- Treating old docs as absolute truth
- Splitting services early for a future assumption
- Adding a layer with no business value for architectural aesthetics
- Mixing in large amounts of implementation tasks
- Modifying business code directly
- Deleting a historical ADR
- Turning an unconfirmed business rule into an architectural fact

## Completion

When the ADR is done, confirm:

1. Current Reality is verified
2. Decision Problem is clear
3. Options are compared
4. Decision and reasoning are clear
5. Consequences are recorded
6. Architecture Drift is handled
7. Documentation impact is clear
8. Whether it is ready to enter PLAN
