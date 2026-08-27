# API Contract Rules

## Goal

Define mandatory constraints for creating or changing application APIs
and integration contracts.

Apply these rules when modifying:

- HTTP APIs
- Webhooks
- Events
- Provider interfaces
- MCP / Tool interfaces
- Shared DTOs
- Public integration contracts

## Rules

### Contract First

Before changing a contract, identify:

- Consumer
- Producer
- Request shape
- Response shape
- Error behavior
- Compatibility impact

Do not change shared contracts as a local implementation detail.

### Ownership

Every contract must have a clear owner.

Do not create duplicate sources of truth for the same contract.

Cross-system contract ownership changes require ADR review.

### Compatibility

Before changing an existing contract, evaluate:

- Existing consumers
- Required fields
- Removed fields
- Renamed fields
- Type changes
- Semantic changes
- Error behavior

Prefer backward-compatible evolution when practical.

Breaking changes require explicit scope and migration planning.

### Validation

Validate external contract input at the system boundary.

Do not assume:

- Client payloads
- Webhook payloads
- Provider responses
- MCP / Tool results

are trusted or structurally correct.

### Error Contract

Errors should be predictable.

When applicable, distinguish:

- Validation error
- Authentication error
- Authorization error
- Not found
- Conflict
- Rate limit
- External dependency failure
- Internal failure

Do not expose internal stack traces or infrastructure details.

### Idempotency

For retryable commands or external delivery,
define idempotency semantics when duplicate execution can cause harm.

The contract should make stable request or event identity available
when required.

### Pagination

Potentially large collection APIs must define bounded retrieval.

When applicable, define:

- Page size
- Cursor or page semantics
- Sort order
- Filter behavior

Avoid unbounded collection responses.

### Webhooks

Webhook contracts should define when applicable:

- Event type
- Event identity
- Timestamp
- Payload schema
- Signature mechanism
- Retry behavior
- Duplicate delivery behavior
- Expected response behavior

### Provider Interfaces

Keep vendor-specific behavior behind the established provider or adapter boundary.

Business logic should depend on stable application-facing contracts
rather than unnecessary vendor SDK details.

### MCP / Tool Contracts

Tool interfaces should have explicit:

- Input schema
- Output schema
- Error behavior
- Side-effect semantics

Do not treat natural-language Tool output as a reliable structured contract
when structured output is required.

Tools with side effects should make those side effects explicit.

### Documentation

Update affected contract documentation when contract behavior changes.

Do not leave documentation describing behavior that no longer exists.

## Validation

Contract changes must execute applicable:

- Schema validation
- Type checking
- Consumer tests
- Provider / adapter tests
- Integration tests
- Compatibility checks

Report:

- PASS
- FAIL
- NOT RUN
- BLOCKED

## Forbidden

- Silent breaking changes
- Duplicate contract definitions without ownership
- Trusting external payloads without validation
- Unbounded growing collection APIs
- Exposing internal errors directly
- Vendor SDK types leaking unnecessarily into business logic
- Natural-language parsing when a required structured contract exists
- Contract changes outside approved scope

## Completion

Before completing a contract change, confirm:

1. Producer and consumers are known.
2. Ownership is clear.
3. Compatibility impact is understood.
4. Input validation exists.
5. Error behavior is defined.
6. Retry / idempotency behavior is understood when relevant.
7. Documentation is synchronized.
8. Applicable validation was actually executed.