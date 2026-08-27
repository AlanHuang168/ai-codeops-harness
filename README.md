# AI CodeOps Harness

AI CodeOps Harness is an engineering development harness for AI Coding Agents.

## Support

- Codex
- Claude Code
- Cursor
- OpenCode: compatible by design; validation is planned.

## Core Capabilities

- Bootstrap
- Router / Resume Protocol
- Authority Model
- Progressive Disclosure
- Runtime Recovery
- Rules / Roles / Workflows
- State / Checkpoint Boundary
- Handoff

## Repository Structure

- `src/workflows/`: workflow authoring source and routing
- `src/roles/`: reusable agent role source
- `src/rules/`: reusable engineering rule source
- `adapters/codex/AGENTS.md`: Codex adapter source
- `adapters/claude/CLAUDE.md`: Claude Code adapter source
- `docs/harness/`: Harness protocols and template boundaries
- `docs/handoff/`: handoff contract

`src/**` is Authoring Source. An installer will generate the installed runtime
layout, including `.ai/**` and project-root adapter files, for each adopting project.
Project Context and Runtime State are supplied by each adopting project and are
not included here.

## Distribution Model

See [`docs/harness/INSTALLER-CONTRACT.md`](docs/harness/INSTALLER-CONTRACT.md)
for the cross-platform distribution contract and conflict policy.

Installer support is not implemented yet.

## Status

Early release: v0.1.0.

Installation/distribution workflow is not implemented yet.
