# Installer Contract

This document defines the cross-platform behavior for a future Installer. It
does not implement `install.sh`, `install.ps1`, or a CLI.

## Source and Runtime

The shared flow is:

```text
Harness Source -> Manifest -> Installer -> Installed Runtime
```

The single source of installation mappings is `manifest/harness.yaml`.

- `src/**` is Harness Authoring Source.
- `.ai/**` is Installed Runtime.
- `adapters/**` is AI Tool Adapter Source.
- Project paths are always repository-relative or project-relative.

## Install

For a first installation, the Installer must:

1. Load and validate `manifest/harness.yaml`.
2. Resolve the target project root.
3. Read Adapter Registry entries from the Manifest.
4. Install the selected stable Adapters.
5. Map `src/rules`, `src/roles`, and `src/workflows` to `.ai/`.
6. Apply the Conflict Strategy before writing each target.
7. Write `.ai/VERSION`.
8. Verify the installed layout.

Harness Core is installed once. Adapters are independently selectable and may
be installed together.

## Update

Update may replace only files recorded as Harness-managed and unchanged since
the last installation. It may update:

- `.ai/rules/**`
- `.ai/roles/**`
- `.ai/workflows/**`
- Harness-managed Adapter files

User-owned files, Project Context, business code, and unknown files are
preserved. An update must never silently overwrite a user-modified file.

## Ownership

Manifest metadata defines ownership and update behavior:

```yaml
owner: harness
update_policy: managed
conflict_policy: abort_on_user_change
```

Runtime ownership categories are:

- `Harness-owned`: files generated from Runtime Mappings.
- `Adapter-owned`: files generated from a selected Adapter.
- `User-owned`: existing, modified, or unknown files not recorded as managed.
- `Generated runtime`: `.ai/VERSION` and installer metadata.

Ownership is determined from the recorded file path and SHA-256, not from
timestamps or file naming assumptions.

## Version

The installed version record is:

```text
.ai/VERSION
```

Minimum schema:

```yaml
name: ai-codeops-harness
version: 0.1.0

installed_adapters:
  - codex
  - claude-code

managed_files:
  - path: .ai/rules/example.md
    sha256: <hex digest>
  - path: AGENTS.md
    sha256: <hex digest>
```

The record contains no user information, Secret, absolute path, or business
fact. A missing or invalid version record is an unknown installation and must
not be upgraded by silently overwriting files.

## Hash Detection

For each managed file:

```text
current hash == recorded hash
-> managed and unchanged
-> safe update

current hash != recorded hash
-> user modified
-> conflict

file exists with no ownership record
-> unknown ownership
-> abort or preserve; never overwrite silently
```

SHA-256 is the only modification signal. Timestamps must not be used.

## Conflict Strategy

The default policy is `abort_on_user_change`.

- `overwrite`: only for Harness-owned, unchanged files, or explicit approval.
- `merge`: not supported for V0.1; no semantic merge is attempted.
- `backup`: may copy a conflicting file before stopping for human decision.
- `abort`: required for unknown ownership or user-modified Adapter files.
- `preserve`: required for unrelated user files.

Unknown `AGENTS.md`, `CLAUDE.md`, and `.ai/**` content must not be
automatically merged or overwritten. Future versions may define managed-block
merge rules.

## Backup

Backups are created only for conflicts:

```text
.ai/backups/<timestamp>/
```

The path is project-relative. Existing backups are not proactively cleaned.
The Installer must avoid creating duplicate backups for the same operation and
must not write Secrets into backup metadata.

## Adapter Selection

The Installer reads all selectable entries from `adapters` in the Manifest.
It must not hard-code the Adapter list. Multiple Adapters may be selected.

Models are not Adapters. Model names such as GPT, Claude, Gemini, Qwen, or
DeepSeek do not receive separate Harness Adapter entries.

## Idempotency

- Reinstalling the same version is safe.
- Identical files are not rewritten unnecessarily.
- Existing user modifications are not overwritten.
- The same operation does not create duplicate backups.
- Partial failure leaves a recoverable state and is not reported as success.
- Re-running uses the Manifest and current disk facts.

## Exit Codes

Both Unix Shell and Windows PowerShell implementations must use these meanings:

```text
0  SUCCESS
1  GENERAL_ERROR
2  INVALID_MANIFEST
3  CONFLICT_ABORTED
4  PARTIAL_FAILURE
5  UNSUPPORTED_ADAPTER
6  INVALID_TARGET
```

## State Machine

```text
START
  -> LOAD_MANIFEST
  -> VALIDATE_MANIFEST
  -> RESOLVE_TARGET_ROOT
  -> READ_VERSION
  -> SELECT_ADAPTERS
  -> CLASSIFY_OWNERSHIP
  -> DETECT_CONFLICTS
       -> BACKUP / MERGE / ABORT
       -> INSTALL_CORE
  -> INSTALL_ADAPTERS
  -> WRITE_VERSION
  -> VERIFY_LAYOUT
  -> COMPLETE
```

Failure states are `VALIDATION_FAILED`, `CONFLICT_ABORTED`, and
`PARTIAL_FAILURE`. An incomplete operation must not be marked `COMPLETE`.

## Cross-platform Requirements

macOS/Linux and Windows share the Manifest, mappings, ownership rules,
conflict policy, Adapter Registry, version semantics, hash algorithm, backup
semantics, and exit-code meanings.

Platform implementations may differ only in filesystem and process APIs. They
must not define separate mapping tables, Adapter lists, or business rules.

Manifest and generated metadata use UTF-8 and project-relative paths. The
contract does not depend on shell syntax, PowerShell syntax, path separators,
or Unix executable bits.
