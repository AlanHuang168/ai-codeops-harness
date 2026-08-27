# Database Rules

## Goal

Define mandatory engineering constraints for database changes.

Apply these rules when a task modifies:

- Schema
- Migration
- Constraints
- Indexes
- Transactions
- Persistence behavior
- Data ownership boundaries

## Rules

### Schema Changes

Production schema changes must use explicit migrations.

Do not rely on automatic schema synchronization as the source of truth.

A schema change must consider:

- Existing data
- NULL behavior
- Defaults
- Constraints
- Indexes
- Backward compatibility
- Migration safety

### Data Ownership

Respect the data ownership defined by the current architecture and accepted ADRs.

Do not write directly to another subsystem's owned data merely because it exists in the same physical database.

Cross-owner writes require an explicit supported contract or architecture decision.

### Invariants

Identify important data invariants before choosing a consistency mechanism.

Prefer database-enforced guarantees when appropriate:

- UNIQUE
- NOT NULL
- FOREIGN KEY
- CHECK
- Transaction

Do not rely only on application pre-checks for concurrency-sensitive invariants.

### Transactions

Use a transaction when multiple database operations must succeed or fail as one consistency unit.

Keep transaction boundaries explicit and as small as practical.

Do not include slow external network calls inside database transactions unless explicitly justified.

### Idempotency

For retryable commands, jobs, or external events, determine whether duplicate execution can create incorrect state.

When idempotency is required, use a stable identity such as:

- Request ID
- Event ID
- External resource ID
- Idempotency key

Back critical uniqueness with a database constraint when appropriate.

### Concurrency

Do not assume:

`read → check → write`

is concurrency-safe.

When concurrent execution matters, evaluate:

- Unique constraints
- Atomic updates
- Optimistic concurrency
- Row locking

Use the simplest mechanism that preserves the required invariant.

### Indexes

Add indexes for demonstrated query patterns.

Evaluate:

- Filter
- Join
- Sort
- Pagination
- Uniqueness

Do not add speculative indexes.

Remember that indexes increase write and storage cost.

### External Side Effects

Do not assume a database transaction can atomically include an external API, message broker, or third-party provider.

When reliable cross-boundary delivery is required, route the design through ADR.

Patterns such as Outbox, retry, or compensation must be justified by the actual failure requirement.

### Migration Safety

Before applying a migration, evaluate:

- Existing rows
- Locking impact
- Large table impact
- Constraint validation
- Index creation
- Application compatibility
- Recovery path

Never delete or destructively transform production data without explicit task scope and approval.

### Query Safety

Avoid:

- Unbounded queries on growing datasets
- N+1 access patterns
- Loading unnecessary columns or rows
- Dynamic SQL built from untrusted input

Use pagination for potentially large collections.

### Validation

Database-related implementation must run the applicable:

- Migration validation
- Type check
- Unit tests
- Integration tests
- Query verification

Report validation as:

- PASS
- FAIL
- NOT RUN
- BLOCKED

Never report unexecuted database validation as PASS.

## Forbidden

- Direct production schema edits outside the migration process
- Silent cross-owner writes
- Application-only uniqueness checks when concurrency safety is required
- Distributed transactions by default
- Sharding without demonstrated scale requirements
- Speculative indexes
- Long external calls inside transactions without justification
- Destructive migration outside explicit scope
- Hiding migration or consistency risks

## Completion

Before completing a database change, confirm:

1. Ownership is respected.
2. Invariants are preserved.
3. Migration is explicit.
4. Transaction boundaries are correct.
5. Concurrency behavior is understood.
6. Required indexes are justified.
7. Failure and retry behavior are understood.
8. Applicable validation was actually executed.