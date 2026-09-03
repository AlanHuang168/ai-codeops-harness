# Contributing

## Principles

- Keep Harness Core generic, minimal, and compatible across AI Coding Agents.
- Keep project-specific context separate from Harness Source.
- Do not commit company or project business knowledge.
- Do not commit secrets, credentials, tokens, private keys, or local runtime state.
- Preserve the boundaries between adapters, Harness Core, Project Context, and Runtime State.
- Keep EVAL metrics, thresholds, regression fixtures, and deployment steps as Project Context; the Harness defines only their shape and obligation, never a specific project's values.

## Before Opening a PR

- Check the basic repository structure and intended file boundaries.
- Run an OSS safety scan for business terms, secrets, internal domains, IPs, and local paths.
- Review the complete diff and confirm no unrelated architecture changes were introduced.

## Harness Definition of Done（Harness 自身完成定义）

Any change to Harness protocol or workflow files must pass the protocol
self-validation before completion:

```bash
tests/harness-contract.sh
```

It verifies no protocol drift across Risk Router tiers, `risk_tier` references,
terminal states, `RELEASE_GATE`, the Acceptance Contract schema, and the EVAL
result enum, and confirms the installer still performs a clean fresh install and
reinstall. It only reads source and installs into a throwaway target; it changes
no protocol semantics. A change is not done while this check fails.
