# Workflow Router

## Purpose

Based on the task's current uncertainty and existing engineering assets,
choose the most appropriate Workflow entry point.

Available stages:

PRD
→ ADR
→ PLAN
→ IMPL

Not every task must start from PRD.

## Routing Principle

Prefer the latest stage from which the task can be completed safely.

Evaluation order:

1. Is the Business clear
2. Is the Architecture clear
3. Is the Implementation Plan clear
4. Can the Task be executed directly and safely

## Route: PRD

Any of:

- New business capability
- Unclear user scenario
- Unclear Scope
- Missing core business rules
- Unclear Acceptance Criteria
- Multiple key business decisions still open

Enter:

PRD

Re-route after PRD is complete.

## Route: ADR

Business requirements are clear, but any of:

- System boundary needs a decision
- Data Owner needs a decision
- Add / remove / merge a subsystem
- Provider / Adapter ownership change
- API / Event architecture change
- Database boundary change
- Authentication or authorization model change
- Introducing significant infrastructure
- Current Reality is inconsistent with an existing ADR

Enter:

ADR

Re-route after the ADR is Accepted.

## Route: PLAN

Business and architecture are clear, but any of:

- Multiple files or modules involved
- Multiple implementation steps
- Task dependencies exist
- Schema / Contract involved
- External integration involved
- A complete validation plan is required
- Direct implementation is high risk

Enter:

PLAN

Enter IMPL after PLAN is Approved（已批准） and an active Approval Record
（活跃审批记录） exists. The Approval Record authorizes continuous IMPL execution
inside the Approved PLAN scope; Router must not require Human Approval again
after each normal Task completion.

## Route: IMPL

All of:

- Business goal is clear
- No architecture decision needed
- Scope is clear
- Change is localized
- Implementation approach is clear
- Low risk
- Validation approach is clear

May go directly to:

IMPL

Typical tasks:

- Well-defined bug fix
- Copy change
- Style adjustment
- Local component change
- Well-defined small-scope code change

## Escalation

Any stage that discovers an upstream problem must escalate.

Business Drift:

→ PRD

Architecture Drift:

→ ADR

Plan Drift:

→ PLAN

Implementation Bug:

→ IMPL

Do not silently resolve an upstream decision in a downstream stage.

## Re-entry

The Workflow is not a one-way linear process.

Allowed:

PRD → ADR
ADR → PLAN
PLAN → IMPL

Also allowed:

PLAN → ADR
IMPL → PLAN
IMPL → ADR
IMPL → PRD

Re-route once the upstream problem is resolved.

Router decides the Workflow entry point. It does not make Task completion an
approval boundary. Under the default `plan_continuous` execution mode, an
Approved PLAN returns to Orchestrator / IMPL for the next READY Task unless a
real Human Gate exists.

## Progressive Disclosure

The Router only decides the entry point.

At this stage, do not load by default:

- All Roles
- All Rules
- All Skills
- All business code

Read only the minimal context needed to make the routing decision.

## Routing Output

Before starting a complex task, state:

Workflow: <PRD | ADR | PLAN | IMPL>

Reason:
<why start here>

Known:
<what is already determined>

Unknown:
<remaining uncertainty>

Required Context:
<context to load for the next stage>

## Forbidden

- Mechanically running the full PRD → ADR → PLAN → IMPL for every task
- Creating a pointless PRD / ADR for a simple task
- Skipping discovered business uncertainty
- Skipping discovered architecture uncertainty
- Bypassing an upstream decision because the AI can guess
- Loading the entire Harness by default
