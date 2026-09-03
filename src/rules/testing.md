# Testing Rules

## Goal

Define mandatory verification constraints for implementation changes.

Apply these rules when a task changes application behavior,
data behavior, integrations, contracts, or user-visible functionality.

## TEST vs EVAL（测试与评估）

These rules define **TEST（测试）**: verification that code, interfaces,
exceptions, and contracts are correct.

They do **not** cover business effect. For parser / algorithm / AI / rule-engine
/ recommendation changes, effect correctness is verified by **EVAL（效果评估）**
— see `eval.md`. A passing test suite is not proof of business effect.

## Rules

### Validation Status and Evidence Kind

Report validation at the actual evidence level. Do not label a result as Executed Test（已执行测试） unless a command, tool, fixture, or system check actually ran.

Use Validation Status（验证状态）:

- PASS — executed and passed
- FAIL — executed and failed
- NOT RUN — not executed
- BLOCKED — execution prevented by a known dependency

Use Evidence Kind（证据类型）:

- Executed Test（已执行测试） — command, tool, fixture, or system check actually ran.
- Human Validation（人工验证） — user or human reviewer actually performed the validation.
- Code-path Review（代码路径审查） — implementation path was inspected; not equivalent to a test.
- NOT RUN（未执行） — validation was not executed and must not be inferred as PASS.

Never infer Executed Test PASS from code inspection alone. Code-path Review（代码路径审查） may support review conclusions, but it is not Executed Test（已执行测试） evidence.

When Harness V2 state is updated, store only minimal Validation Summary（验证摘要）: status, evidence kinds, execution date when applicable, and checkpoint path when applicable. Detailed logs and command output belong outside State（状态）.

### Risk-Based Testing

Testing depth must match change risk.

Select only applicable verification:

- Format
- Lint
- Type check
- Unit test
- Integration test
- End-to-end test
- Build
- Manual verification
- Security verification

Do not require every test level for every change.

### Requirement Coverage

Tests must verify confirmed requirements and acceptance criteria.

Do not invent expected behavior.

If expected behavior is unclear:

→ Business Drift
→ PRD

### Regression

Bug fixes should include regression coverage when practical.

A regression test should:

1. Fail for the original defect.
2. Pass after the fix.
3. Verify observable behavior.

Do not modify expected results merely to make an incorrect implementation pass.

A bug fix's Regression Protection（回归保护） is the output of the Root Cause Gate
（根因门禁, see `impl.md`）: the stated root cause determines what the regression
case must lock in so the same defect cannot silently return.

### Regression Dataset（回归数据集）

For parser / algorithm / AI / rule-engine / recommendation subsystems, the
regression dataset is a first-class artifact, not an optional extra:

```text
tests/fixtures/        # inputs + expected outputs (project-owned)
<regression runner>    # project-owned command that runs the fixtures
```

Rules:

- Every change to such a subsystem must run the existing regression cases before
  completion.
- `pytest passed`（或等价测试通过） alone is not sufficient business-correctness
  evidence; pair it with the regression dataset and EVAL（see `eval.md`）.
- Fixtures, expected outputs, and the runner are project inputs, resolved on
  demand like Project Context. The harness never carries project-specific
  fixtures, metrics, or thresholds.
- If an effect-bearing subsystem has no regression dataset, record the gap as a
  Follow-up rather than declaring business correctness on TEST alone.

### Happy Path

Verify the primary expected behavior.

Do not stop at the happy path when meaningful failure conditions exist.

### Failure Paths

When relevant, verify:

- Invalid input
- Missing resources
- Conflict
- Duplicate execution
- Unauthorized access
- Forbidden access
- Timeout
- External provider failure
- Database failure
- Partial failure
- Retry

Only test failure scenarios relevant to the actual task.

### Idempotency and Retry

When operations may be retried or delivered more than once,
verify observable duplicate behavior.

Where concurrency is part of the risk,
a sequential duplicate test alone is not sufficient evidence.

### Integration Boundaries

Use integration testing when correctness depends on:

- Database constraints
- Transactions
- Repository behavior
- API contracts
- Provider adapters
- Multiple application components

Do not replace an important integration guarantee
with a unit test that cannot verify it.

### Mocking

Mock external dependencies when isolation is useful.

Do not mock away the behavior being tested.

Examples:

If verifying database uniqueness,
do not replace the database with an in-memory mock.

If verifying provider request mapping,
mock the remote provider boundary rather than the mapping logic itself.

### Test Isolation

Tests should be:

- Deterministic
- Repeatable
- Independent when practical
- Explicit about required external dependencies

Do not depend on production data or production credentials.

### External Verification

If real external verification requires unavailable:

- Credentials
- Public endpoints
- Provider sandbox
- Hardware
- Infrastructure

report:

NOT RUN（未执行）

or:

BLOCKED（阻塞）

Do not simulate the external system and report it as real E2E verification.

### Security Verification

For security-sensitive changes, test applicable:

- Authentication
- Authorization
- Resource ownership
- Tenant isolation
- Invalid signatures
- Replay behavior
- Input validation
- Sensitive data exposure

Do not disable security controls to make tests pass.

### Migration Verification

For database changes, verify applicable:

- Migration execution
- Existing data compatibility
- Constraints
- Indexes
- Rollback or recovery assumptions

A successful application build does not prove a migration is safe.

### Final Validation

Before completion:

1. Run task-level validation.
2. Run applicable regression checks.
3. Run applicable project-level checks.
4. Record commands or verification performed.
5. Report failures and skipped checks explicitly.

## Forbidden

- Claiming unexecuted tests passed
- Changing tests only to match incorrect implementation
- Deleting failing tests without justification
- Mocking away the behavior under verification
- Treating compilation as functional verification
- Treating unit tests as proof of external integration
- Using production credentials in normal automated tests
- Hiding skipped, blocked, or failed validation
- Chasing coverage percentage without risk justification

## Completion

Before declaring verification complete, confirm:

1. Required behavior was tested.
2. Relevant failure paths were considered.
3. Regression risk was evaluated.
4. Appropriate test level was used.
5. Important integration behavior was not mocked away.
6. Actual execution status was reported accurately.
