# PRD Workflow

## Purpose

Turn a user's business need into clear, verifiable product requirements
that serve as the business basis for the ADR and later development.

A PRD describes:

- Why
- Who
- What
- Scope
- Acceptance

A PRD does not decide technical implementation.

## Lifecycle

PRD Workflow lifecycle:

Clarify
→ Ready
→ User Approval
→ Accepted
→ Persist
→ Exit

Definitions:

- PRD Ready = no blocking Business Unknown remains, but the user has not necessarily accepted it.
- PRD Accepted = PRD Ready + explicit user approval.
- PRD Persisted = Accepted PRD has been written as an official project artifact under `docs/prd/`.
- PRD Approval Persisted = explicit user approval has been written as an Approval Record（审批记录） under `.ai/state/approvals/`.

Only a Persisted + Accepted PRD can be used as the formal upstream input for ADR / PLAN.

## Triggers

Enter PRD when any of:

- New business capability
- New user scenario
- Unclear requirement goal
- Unclear acceptance criteria
- Multiple business roles involved
- Business process change involved
- User explicitly requests requirement design

PRD can usually be skipped for:

- Well-defined bug
- Minor UI tweak
- Small change to an existing feature
- Follow-up development where a valid PRD already exists

## Process

### 1. Problem

Clarify:

- Current problem
- Why it needs solving
- Current process
- Expected improvement

Do not substitute a technical problem for the business problem.

### 2. User

Identify:

- Primary User
- Related User
- Administrator
- External Actor

Keep only the roles relevant to the current need.

### 3. Scenario

Describe the core business scenarios:

Actor
→ Trigger
→ Action
→ Result

Describe the real business flow first.

### 4. Requirement

Organize functional requirements.

Each requirement should state:

- Trigger
- Input
- Behavior
- Output

Avoid describing specific technical implementation.

### 5. Business Rules

Record already-confirmed business rules.

For example:

- State transition conditions
- Deduplication definition
- Assignment rules
- Permission rules
- Time rules

Unconfirmed rules must be marked:

TODO(decision)

The AI must not decide them on its own.

### 6. Scope

Clarify:

In Scope
- Must be done this cycle

Out of Scope
- Explicitly not done this cycle

Future
- May be considered later

Do not build features early via Future Scope.

### 7. Acceptance Criteria

Describe completion using verifiable outcomes.

Prefer:

Given
When
Then

Or an equivalent explicit acceptance condition.

### 8. Open Questions

Record:

- Unconfirmed business rules
- External dependencies
- Questions needing product/business confirmation

## PRD Output

At minimum:

1. Background / Problem
2. Goal
3. Users
4. User Scenarios
5. Functional Requirements
6. Business Rules
7. Scope
8. Acceptance Criteria
9. Open Questions

## Artifact Persistence

When the user explicitly accepts a PRD, persist it as an official project artifact.

Default path:

`docs/prd/`

Recommended naming:

`PRD-NNNN-<slug>.md`

An Accepted PRD artifact must preserve:

- Status
- Version
- Acceptance Criteria
- Open Questions

Non-blocking Open Questions do not block Accepted status.

Do not change a Proposed / Ready PRD to Accepted without explicit user approval.

## Forbidden

In the PRD stage:

- Designing database tables
- Deciding Schema
- Deciding API paths
- Deciding service decomposition
- Deciding message queues
- Deciding Provider implementation
- Modifying code
- Modifying architecture
- Writing AI speculation as a business rule

## Exit Gate

The PRD Workflow is complete only when all of:

1. PRD Ready = YES
2. User Approval has been obtained
3. Status = Accepted
4. Artifact has been persisted
5. Approval Record has been persisted when Harness V2 Runtime State is available
6. Blocker = 0

Before Exit, confirm:

1. Business goal is clear
2. Users and scenarios are clear
3. Scope is clear
4. Acceptance criteria are verifiable
5. Blocking Business Unknowns are resolved
6. Non-blocking Open Questions are recorded
7. The Accepted PRD artifact exists under `docs/prd/`
8. The Approval Record is referenced from Runtime State when state updates are allowed

After Exit, re-run the Router.

Do not assume ADR or PLAN just because PRD is complete.
