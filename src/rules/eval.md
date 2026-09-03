# Evaluation Rules（EVAL 规则）

## Goal

Separate **TEST（测试）** from **EVAL（效果评估）** and define a generic,
project-agnostic Eval Contract.

- TEST verifies that code, interfaces, exceptions, and contracts are correct.
- EVAL verifies that the change produces the required business effect on a
  dataset.

Apply EVAL when a task changes the behavior of a subsystem whose correctness is
an **effect** rather than only a code path: parser, algorithm, AI / model, rule
engine, or recommendation.

TEST alone is not sufficient business-correctness evidence for these subsystems.
`pytest passed`（或等价测试通过） does not prove the effect is still correct.

## TEST vs EVAL（测试与评估的区别）

| | TEST（测试） | EVAL（效果评估） |
|---|---|---|
| Verifies | code / interface / exception / contract | business effect / output quality |
| Evidence | Executed Test, Human Validation, Code-path Review | measured metric against a target on a dataset |
| Fails when | code is wrong | output quality regresses even if code is "correct" |

See `testing.md` for TEST rules. This file owns EVAL.

## Eval Contract（评估契约）

The harness defines the **shape and obligation** only. It binds **no** specific
metric or threshold. The project supplies metrics, datasets, targets, and the
runner.

```yaml
eval:
  - metric: <name>          # e.g. accuracy | exact_match | precision | recall
    dataset: <path>         #      | latency_p50 | latency_p95 | error_rate
    target: <threshold>     #      | business_acceptance_rate | project-defined
    measurement: <how the metric is measured>
    result: <PASS | FAIL | NOT_RUN | BLOCKED>
```

Rules:

- The project owns metric names, datasets, and targets. Do not invent thresholds.
- Report `result` at the actual evidence level. `NOT_RUN` must not be reported
  as `PASS`.
- If the task has no declared effect metric, record EVAL as `N/A` with a one-line
  reason; do not fabricate a metric.
- If a required dataset, model, or environment is unavailable, report `BLOCKED`,
  not a simulated result.

## Regression Dataset（回归数据集）

For parser / algorithm / AI / rule-engine / recommendation subsystems, the
regression dataset is a first-class artifact, provided by the project:

```text
tests/fixtures/        # inputs + expected outputs (project-owned)
<regression runner>    # project-owned command that runs the fixtures
```

Rules:

- Every change to such a subsystem MUST run the existing regression cases.
- A regression case should fail before a defect fix and pass after it.
- Do not edit expected outputs merely to make an incorrect implementation pass.
- Fixtures, expected outputs, and the runner are **project inputs**, resolved on
  demand like Project Context. The harness never carries project-specific
  metrics or fixtures.

If a project has no regression dataset for an effect-bearing subsystem, record
that gap as a Follow-up rather than declaring business correctness on TEST alone.

## Acceptance Contract — Business Half（验收契约 · 业务）

EVAL results feed the **business** half of the Acceptance Contract defined in
`plan.md` and verified in `impl.md`:

```yaml
acceptance:
  business:
    - expected fixture outputs match
    - latency target satisfied
```

Review MUST NOT return PASS while a declared business acceptance item is unmet
or its EVAL result is `FAIL`.

## Forbidden

- Reporting TEST PASS as proof of business effect.
- Fabricating a metric, dataset, or threshold not defined by the project.
- Editing expected outputs to mask a regression.
- Simulating an unavailable dataset or model and reporting it as a real result.
- Skipping existing regression cases on an effect-bearing change.

## Completion

Before declaring EVAL complete, confirm:

1. The applicable effect metric(s) were measured, or EVAL is justified as `N/A`.
2. Existing regression cases were run for effect-bearing subsystems.
3. Results were reported at the actual evidence level.
4. Business acceptance items are satisfied or accurately reported as unmet.
