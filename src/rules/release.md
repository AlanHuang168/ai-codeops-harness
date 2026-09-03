# Release / Deployment Rules（发布 / 部署规则）

## Goal

Distinguish **Code Done（代码完成）** from **Delivery Done（交付完成）**.

For deployable projects — a service, server, or distributable package — a change
is not delivered when it merely compiles and passes tests. Delivery requires the
release surface to be verified.

Apply these rules when the change affects a deployable or distributable artifact.
For a library or non-deployable change, record the Release Gate as `N/A`.

## Release Gate（发布门禁）

Release is an irreversible External Side Effect（外部副作用）. It always requires
a Human Gate regardless of Risk Tier, and stops at the `RELEASE_GATE` /
`APPROVAL_REQUIRED` terminal state until a human authorizes it.

Before requesting release approval, check and report the state of each
applicable item:

- README — usable and current
- API usage — documented and consistent with the change
- Health check — exists and reflects real service health
- Deployment docs — how to deploy the new version
- Upgrade procedure — how to move an existing deployment forward
- Rollback — how to revert safely
- Smoke test — minimal post-deploy verification
- Runtime config — required configuration and its defaults are documented

Report each as `OK`, `MISSING`, `N/A`, or `BLOCKED`. Do not report an unchecked
item as `OK`.

## Delivery Definition of Done（交付完成定义）

For a deployable change, Delivery Done requires:

1. Code Done: format, lint, typecheck, tests, build (see `AGENTS.md` DoD).
2. Acceptance Contract satisfied (technical + business).
3. EVAL satisfied or justified as `N/A`.
4. Release Gate items checked and reported.
5. Human approval of the release recorded when the project deploys or publishes.

Code Done is a precondition for Delivery Done, not a substitute.

## Boundary（边界）

- The harness defines **which** release items to check, not the project's deploy
  commands, environments, or infrastructure. Those are project inputs, resolved
  on demand like Project Context.
- Do not embed any specific project's deployment steps, endpoints, or config
  values into the harness.

## Forbidden

- Declaring a deployable change "done" on Code Done alone.
- Performing release, deploy, publish, push, or merge without the Human Gate.
- Reporting an unchecked release item as OK.
- Copying project-specific deployment details into the harness.

## Completion

Before declaring Delivery Done, confirm:

1. Code Done is met.
2. Acceptance Contract and applicable EVAL are satisfied or accurately reported.
3. Applicable Release Gate items were checked and reported.
4. Release authorization is recorded when the project actually deploys or
   publishes.
