# Change Risk Router

## Purpose

Before selecting a Workflow stage or starting work, classify the change by
Risk（风险）— its blast radius and reversibility — and choose the matching
execution path.

This router does **not** replace `router.md`. `router.md` still owns stage
selection (PRD / ADR / PLAN / IMPL) by uncertainty. The Change Risk Router runs
**first** and maps each risk tier onto those existing stages and Human Gates.

The Agent must classify **before** implementing, and must state the tier and the
one trigger that selected it.

## Risk Tiers（风险分级）

Classify by the highest matching tier. Ambiguity escalates **upward**
(Fast → Standard → Architecture), never downward. Never downgrade a tier to
skip a gate.

### Architecture Path（架构路径 / High Risk）

Select if **any** of:

- Architecture, system boundary, or data ownership change
- Data model / schema change or Migration（迁移）
- Breaking API / breaking Contract semantics change
- Security / authentication / authorization / tenancy change
- Infrastructure or cross-system protocol change
- Destructive or irreversible operation

### Standard Path（标准路径 / Medium Risk）

Select if **any** of (and no Architecture trigger):

- Medium feature
- New module or component
- Non-breaking API behavior change
- Multi-file business logic change
- Change to parser / algorithm / AI / rule-engine / recommendation behavior
  that has an effect metric — this **forces EVAL**（see `eval.md`）

### Fast Path（快速路径 / Low Risk）

Select only if **all** of:

- Small bug fix, small localized feature, local refactor, or docs fix
- Single subsystem, well understood, low blast radius
- No schema, contract, security, migration, or release surface
- Validation approach is obvious

## Path Flows（路径流程）

Each path maps to existing stages and gates. Nothing here bypasses a real
Human Gate defined by Harness V2.

### Fast Path

```text
Reality
-> Root Cause / Mini Plan
-> Implement
-> Test
-> Review
```

- Maps to: direct IMPL.
- Human Approval: 0 new approvals (executes inside existing in-scope
  authorization).
- Bug fixes MUST pass the Root Cause Gate（see `impl.md`）before a high-impact
  change.

### Standard Path

```text
Reality
-> PLAN
-> Human Approval (1x)
-> Implement
-> Test
-> EVAL*
-> Review
-> Acceptance Contract
```

- Maps to: PLAN -> Approval Record -> IMPL under `plan_continuous`.
- Human Approval: 1 PLAN approval, then continuous execution.
- `*EVAL` runs only when the task has a declared effect metric; otherwise
  record EVAL as `N/A`.

### Architecture Path

```text
Reality
-> ADR
-> PLAN
-> Human Approval (key nodes)
-> Implement
-> Verify
-> EVAL*
-> Review
-> Acceptance Contract
-> Release Gate
```

- Maps to: ADR -> PLAN -> Approval Record -> IMPL, plus Release Gate（see
  `release.md`）when the project is deployable.
- Human Approval at key nodes: ADR acceptance, PLAN approval, and Release Gate.
- Irreversible operations keep their existing Human Gate regardless of tier.

## Risk Tier to Approval Mapping（风险分级与审批映射）

| Tier | New Human Approvals | Mechanism (already in Harness V2) |
|---|---|---|
| Low (Fast) | 0 | in-scope authorization, direct IMPL |
| Medium (Standard) | 1 (PLAN) | one Approval Record, `plan_continuous` |
| High (Architecture) | key nodes: ADR + PLAN (+ Release Gate) | ADR approval + PLAN Approval Record + Release Gate |

`risk_tier`（风险分级） is recorded as an optional field on the PLAN and the
Approval Record. When absent, Runtime treats the change as **Standard**.

The following irreversible operations always require a Human Gate regardless of
tier: data deletion, database Migration（迁移）, auth / authz change, breaking
API, release, and `git push` / merge / deploy / publish. These remain the
existing `DESTRUCTIVE_ACTION`, `SECURITY_GATE`, external side-effect, and
`RELEASE_GATE` terminal states.

## Escalation（升级）

Discovering a higher-tier trigger mid-flow escalates immediately, reusing the
existing Drift / Gate escalation:

- Architecture trigger found -> ADR（`ARCHITECTURE_DRIFT` / `APPROVAL_REQUIRED`）
- Scope beyond Approved PLAN -> PLAN（`SCOPE_EXPANSION` / `APPROVAL_REQUIRED`）
- Security / destructive / release surface found -> corresponding Human Gate

## Routing Output（路由输出）

Before starting a non-trivial task, state:

```text
Risk Tier: <Fast | Standard | Architecture>
Trigger:   <the one condition that selected this tier>
Path:      <path flow>
EVAL:      <required | N/A>
Release Gate: <required | N/A>
```

Then hand off to `router.md` for stage selection.

## Forbidden

- Defaulting every task to the full heavy path.
- Downgrading a tier to skip Root Cause, EVAL, Acceptance Contract, or Release
  Gate.
- Treating risk classification as a substitute for a real Human Gate.
- Step-by-step approval: AI does one step -> human approves -> AI does next step.
