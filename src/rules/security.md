# Security Rules

## Goal

Define mandatory security constraints for application development.

Apply these rules when a task involves:

- Authentication
- Authorization
- User or tenant data
- External input
- Webhooks
- APIs
- Secrets
- PII
- File uploads
- External providers

## Rules

### Trust Boundaries

Treat all external input as untrusted.

This includes:

- HTTP requests
- Webhooks
- Browser input
- Uploaded files
- External APIs
- Provider callbacks
- MCP / Tool results

Validate input before using it in trusted application logic.

### Authentication

Protected operations must require server-side authentication.

Do not rely on:

- UI state
- Hidden routes
- Client-side flags
- User-supplied identity fields

Never trust identity information supplied by the client when
the authenticated session already provides authoritative identity.

### Authorization

Authentication does not imply authorization.

For protected resources, evaluate:

- Role permission
- Resource ownership
- Tenant / organization boundary
- Action permission

Authorization must be enforced server-side.

UI visibility is not an authorization boundary.

### Tenant Isolation

When data is tenant-scoped:

- Derive tenant identity from trusted authentication context.
- Do not trust client-provided tenant IDs without authorization.
- Include tenant scope in reads and writes where required.
- Prevent cross-tenant enumeration and access.

Cross-tenant operations require explicit authorization.

### Secrets

Secrets must not be:

- Committed to source control
- Hard-coded in application code
- Embedded in client bundles
- Written to normal logs
- Included in error responses
- Stored in documentation examples

Do not read secret-bearing `.env*` files unless the current task
explicitly requires configuration verification.

Prefer:

- `.env.example`
- documented environment variable names
- runtime diagnostics
- user-provided sanitized configuration

If secret-bearing configuration must be inspected:

- Read only the minimum required configuration.
- Never expose secret values in output.
- Never copy secret values into logs, documentation, tests, or prompts.

Use approved environment or secret management mechanisms.

Examples include:

- API keys
- Access tokens
- Refresh tokens
- Webhook secrets
- Database credentials
- Session secrets

### PII

Collect and expose only the personal data required by the task.

When applicable:

- Mask sensitive values in logs
- Limit API response fields
- Restrict exports
- Avoid unnecessary duplication
- Respect ownership and access rules

Do not log full sensitive payloads by default.

### Webhooks

External webhooks must be treated as untrusted requests.

When supported by the provider, verify:

- Signature
- Timestamp
- Source authenticity

When replay or duplicate delivery can cause harm, evaluate:

- Replay protection
- Event identity
- Idempotency

HTTPS alone does not prove webhook authenticity.

### Input Validation

Validate external input for:

- Type
- Format
- Length
- Allowed values
- Required fields
- Size limits

Use allowlists when practical.

Do not build SQL, commands, paths, or executable expressions
through unsafe string concatenation.

### External Providers

For external APIs and SDKs:

- Keep credentials server-side
- Apply timeouts
- Handle provider failures explicitly
- Avoid leaking provider errors directly to users
- Log enough context for diagnosis without leaking secrets or PII

Do not assume third-party responses are trusted input.

### Error Handling

Public errors must not expose:

- Stack traces
- Credentials
- Internal paths
- SQL details
- Infrastructure details
- Sensitive payloads

Preserve diagnostic details only in appropriate internal observability.

### Logging

Logs must not contain secrets.

Mask or omit sensitive personal data when full values are unnecessary.

Security-relevant actions should be auditable when required by the product.

### Rate and Abuse Protection

For public or externally reachable endpoints, evaluate:

- Rate limiting
- Brute-force risk
- Enumeration
- Duplicate submission
- Resource exhaustion
- Automated abuse

Apply protection according to actual risk.

Do not add complex infrastructure without demonstrated need.

## Validation

For security-relevant changes, execute applicable verification such as:

- Authentication tests
- Authorization tests
- Invalid input tests
- Cross-tenant access tests
- Webhook verification tests
- Replay / duplicate tests
- Secret exposure checks

Report:

- PASS
- FAIL
- NOT RUN
- BLOCKED

Never report unexecuted security verification as PASS.

## Forbidden

- Client-only authorization
- Trusting user-supplied ownership without verification
- Unverified external input entering trusted logic
- Hard-coded secrets
- Secrets in logs
- Full PII logging by default
- Cross-tenant access without authorization
- Returning internal errors directly to public clients
- Treating HTTPS as webhook authentication
- Disabling security controls merely to make tests pass

## Completion

Before completing a security-relevant change, confirm:

1. Trust boundaries are understood.
2. Authentication is enforced where required.
3. Authorization is server-side.
4. Tenant isolation is preserved.
5. Secrets remain protected.
6. PII exposure is minimized.
7. External input is validated.
8. Webhook authenticity is handled when applicable.
9. Abuse risks were evaluated when applicable.
10. Security validation was actually executed.