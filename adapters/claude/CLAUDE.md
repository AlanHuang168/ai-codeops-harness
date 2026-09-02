# CLAUDE.md

## Role

Claude Code adapter and bootstrap only.
It does not own Harness Core or Project Context.

## Bootstrap

1. Read `AGENTS.md`.
2. Follow its bootstrap, routing, and recovery rules.
3. Resolve project facts from `docs/project/PROJECT.md` when needed.
4. Load other `docs/project/*` documents only on demand.

## Authority

- Harness Core: `AGENTS.md` + `.ai/`
- Project Context: `docs/project/`
- Runtime State: `.ai/state/`

## Progressive Disclosure

Load only the minimum context required for the current task.
Do not copy Project Context into this file.

## Compatibility

Keep `CLAUDE.md` as the stable Claude Code entry point.
It must not become a Project Context or second Harness Core authority.
