# Harness Template Boundary（Harness 模板边界）

- Boundary Version: 0.1
- Status: Active
- Layer: Harness Protocol（Harness 协议规范）
- Related Decision: ADR-0006 Harness Core and Project Context Decoupling
- Related Plan Task: PLAN-0002 Task 7

## Purpose（目的）

This document defines **what a portable Harness template provides** and **what every adopting project must provide itself**. It is project-agnostic and does not describe any particular project.

## Explicitly Out of Scope（明确排除）

At this boundary version:

- **No CLI**（不实现命令行工具）. No generator, scaffolder, or installer is defined or implied.
- **No automatic substitution**. Placeholder substitution is manual.
- **No file removal**. Adopting the template never requires deleting an existing project document.
- **No business behaviour**. The template carries no domain logic, schema, API, or deployment content.

A future CLI, if ever proposed, requires its own decision. This document does not authorize one.

## What the Template Provides（模板提供什么）

### 1. Directory Contract（目录契约）

```text
adapters/codex/AGENTS.md      Codex adapter source（Codex 适配器源码）
adapters/claude/CLAUDE.md    Claude adapter source（Claude 适配器源码）
src/workflows/                Workflow authoring source（工作流源码）
src/roles/                    Role authoring source（角色源码）
src/rules/                    Generic engineering constraints（通用工程约束源码）
.ai/                          Installed Harness Runtime（已安装 Harness 运行时）
.ai/state/                    Runtime State（运行状态）
.ai/state/checkpoints/tasks/  Per-task checkpoints（按任务检查点）
docs/harness/                 Harness Protocol（协议规范）
{{CONTEXT_DIR}}/              Project Context（项目上下文，默认 docs/project）
docs/handoff/                 Non-authoritative handoff（非权威交接）
```

### 2. Generic Documents（通用文档）

Carried as-is, containing no project facts:

- Harness Core entry and workflow / role / rule documents.
- `docs/harness/HARNESS-V2.md` — runtime recovery protocol.
- `docs/harness/PROJECT-CONTEXT-CONTRACT.md` — the Project Context contract.
- This boundary document.

### 3. Placeholders（占位符）

Substituted manually when a project adopts the template:

| Placeholder | Meaning |
|---|---|
| `{{PROJECT_NAME}}` | Human-readable project name |
| `{{PROJECT_SLUG}}` | Short machine-safe identifier |
| `{{WORKSPACE_SHAPE}}` | `single-repo` \| `monorepo` \| `side-by-side-repos` |
| `{{SUBSYSTEM_LIST}}` | Subsystem inventory entries |
| `{{PRIMARY_DOMAIN_TERMS}}` | Seed entries for the glossary |
| `{{CONTEXT_OWNER}}` | Role or team accountable for Project Context |
| `{{CONTEXT_DIR}}` | Project Context directory, default `docs/project` |
| `{{TEST_DATABASE_NAME}}` | Isolated test database name used in `exclusive_resource` examples |
| `{{TEST_SERVER_PORT}}` | Test server port used in `exclusive_resource` examples |

### 4. Empty Runtime State Skeleton（空运行状态骨架）

A minimal `execution-state.yaml` shape carrying recovery fields and a `project_context` reference, with no task history and no project knowledge.

## What the Project Must Provide（项目必须自行提供）

A template cannot infer these. Adoption is incomplete until they exist:

| Required input | Where it lands | Why a template cannot supply it |
|---|---|---|
| Project identity and scope | `{{CONTEXT_DIR}}/PROJECT.md` | Only the project knows what it is |
| Workspace shape and command locations | `{{CONTEXT_DIR}}/PROJECT.md` | Repository topology varies |
| Subsystem inventory and statuses | `{{CONTEXT_DIR}}/PROJECT.md` | Depends on what has been built |
| Hard constraints and prohibitions | `{{CONTEXT_DIR}}/PROJECT.md` | Encodes the project's own decisions |
| System boundaries and data ownership | `{{CONTEXT_DIR}}/SYSTEM_MAP.md` | Ownership is a project decision |
| Domain vocabulary and forbidden terms | `{{CONTEXT_DIR}}/GLOSSARY.md` | Domain-specific |
| Concrete convention values | `{{CONTEXT_DIR}}/CONVENTIONS.md` | Core owns the constraint class; the project owns the value |
| Accepted PRD / ADR / approved PLAN | Project decision directories | Governance content, not template content |
| AI adapter file for the agent in use | For example `CLAUDE.md` | Depends on which agent the project uses |

## Adoption Checklist（采纳清单）

1. Copy the directory contract and generic documents.
2. Substitute every placeholder; leaving one unsubstituted is a defect.
3. Create the four Project Context documents per `PROJECT-CONTEXT-CONTRACT.md`.
4. Write the AI adapter file as an adapter only; it must not become a second Core entry.
5. Initialize Runtime State with a `project_context` reference and no task history.
6. Confirm conformance using the contract's Conformance section.

## Migrating an Existing Project（既有项目迁移）

Adoption in a project that already has context documents follows the contract's compatibility rules: add before removing, declare source references, keep exactly one authority per fact, do not move or delete original files, and treat deprecation as a separate decision.
