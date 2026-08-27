# Contributing

## Principles

- Keep Harness Core generic, minimal, and compatible across AI Coding Agents.
- Keep project-specific context separate from Harness Source.
- Do not commit company or project business knowledge.
- Do not commit secrets, credentials, tokens, private keys, or local runtime state.
- Preserve the boundaries between adapters, Harness Core, Project Context, and Runtime State.

## Before Opening a PR

- Check the basic repository structure and intended file boundaries.
- Run an OSS safety scan for business terms, secrets, internal domains, IPs, and local paths.
- Review the complete diff and confirm no unrelated architecture changes were introduced.
