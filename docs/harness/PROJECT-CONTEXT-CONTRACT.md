# Project Context Contract（项目上下文契约）

- Contract Version: 0.1
- Status: Active
- Layer: Harness Protocol（Harness 协议规范）
- Related Decision: ADR-0006 Harness Core and Project Context Decoupling
- Related Plan Task: PLAN-0002 Task 1

## Purpose（目的）

This contract defines the **minimum portable shape** of Project Context（项目上下文） so that Harness Core（Harness 核心框架） can operate on any project without depending on a specific product, company, or business domain.

It is **project-agnostic**（与具体项目无关）. It describes *what a project must provide*, not what any particular project contains.

## Non-Goals（非目标）

This contract does **not**:

- Restate Workflow（工作流）, Governance（治理）, or Runtime Recovery（运行恢复） rules. Those remain owned by Harness Core and the Harness Protocol; see `AGENTS.md`, `.ai/workflows/`, and `docs/harness/HARNESS-V2.md`. **A second rule set must never be created here.**
- Store runtime state, validation logs, or recovery facts. Those belong to Runtime State（运行状态）.
- Define tooling. A CLI or generator is explicitly out of scope at this contract version.
- Require any project to abandon its existing document layout during a compatibility phase.

## Authority Model Position（在权威模型中的位置）

Per ADR-0006:

```text
CLAUDE.md            -> AI Adapter / Bootstrap（AI 入口适配）
AGENTS.md + .ai/     -> Harness Core（通用核心框架）
docs/harness/        -> Harness Protocol（Harness 协议规范）   <- this contract lives here
docs/project/        -> Project Context（项目事实与业务上下文）  <- this contract governs that
.ai/state/           -> Runtime State（运行状态）
```

Precedence（优先级）: Accepted PRD / ADR / business PLAN and Current Reality（当前事实） outrank Project Context documents. Project Context outranks any project facts that remain embedded in Harness Core or an AI Adapter file.

## Required Documents（必需文档）

A conforming project provides four documents under its Project Context directory（默认 `docs/project/`）:

| Document | Answers（回答的问题） | Authority（权威范围） |
|---|---|---|
| `PROJECT.md` | What is this project, what are its parts, what are the hard constraints? | Project identity, scope, subsystem inventory, non-negotiable constraints |
| `SYSTEM_MAP.md` | What systems exist and who owns what? | System boundaries, ownership, data ownership, integration points |
| `GLOSSARY.md` | What do the domain terms mean? | Canonical domain vocabulary and forbidden/ambiguous terms |
| `CONVENTIONS.md` | How does this project name and build things? | Project-specific naming, data, and delivery conventions |

A project **may** add further documents. Additional documents must not redefine Harness Core rules.

## Required Sections（必需章节）

Each document carries a header block, then its required sections. Section titles may be localized, but the required content must be present and findable.

### Common Header（通用头部）

```text
- Context Version（上下文版本）
- Status（状态）: Active | Draft | Superseded
- Owner（归属）: the role or team accountable for keeping this accurate
- Last Reviewed（最近复核）
- Source References（来源引用）: files this document was derived from, during a compatibility phase
```

### `PROJECT.md`

1. **Identity（身份）** — what the project is, in one paragraph.
2. **Workspace Shape（工作区形态）** — single repository, monorepo, or side-by-side repositories; where commands must be run.
3. **Subsystem Inventory（子系统清单）** — each part, its status, and one line on responsibility.
4. **Hard Constraints（硬约束）** — things an agent must never do in this project.
5. **Entry Points（入口）** — where to start reading for a given kind of task.

### `SYSTEM_MAP.md`

1. **System Boundaries（系统边界）** — what each system owns.
2. **Data Ownership（数据归属）** — which system is the source of truth for which data.
3. **Integration Points（集成点）** — contracts, APIs, events, and shared stores.
4. **Read-only vs Write Relationships（只读与写入关系）** — explicit cross-system access rules.

### `GLOSSARY.md`

1. **Canonical Terms（规范术语）** — term, definition, and the system that owns it.
2. **Disambiguation（易混词区分）** — terms that are commonly confused.
3. **Forbidden Terms（禁用术语）** — terms that must not be used, and what to use instead.

### `CONVENTIONS.md`

1. **Naming（命名）** — code, data, and artifact naming rules specific to this project.
2. **Data and Storage（数据与存储）** — project-specific data conventions.
3. **Delivery（交付）** — build, environment, and deployment conventions.
4. **Explicit Precedence（优先级声明）** — for any rule that also exists generically, state which one wins.

## Authority and Update Ownership（权威与维护归属）

- Every Project Context document declares an `Owner`（归属）.
- A change to project facts updates Project Context first; other documents reference it rather than restating it.
- Harness Core and AI Adapter files **reference** Project Context; they must not become a second copy of it.
- When Project Context and Current Reality（当前事实） disagree, Current Reality wins and the document must be corrected.

## Compatibility Rules（兼容规则）

For a project migrating from an existing layout:

1. **Add before removing.** Create the Project Context documents while the original files stay in place.
2. **Declare the source.** Each new document lists its `Source References`（来源引用）.
3. **Name one owner per fact.** While two locations exist, exactly one is authoritative; the other carries a pointer.
4. **Do not move or delete** original context files during the compatibility phase.
5. **Deprecation is a separate decision.** Removing or relocating old paths requires its own review, not an incidental edit.

## Template Placeholders（模板占位符）

A portable template supplies the directory contract and these placeholders only. Substitution is manual at this contract version; no CLI is defined.

```text
{{PROJECT_NAME}}            Human-readable project name
{{PROJECT_SLUG}}            Short machine-safe identifier
{{WORKSPACE_SHAPE}}         single-repo | monorepo | side-by-side-repos
{{SUBSYSTEM_LIST}}          Subsystem inventory entries
{{PRIMARY_DOMAIN_TERMS}}    Seed entries for the glossary
{{CONTEXT_OWNER}}           Role or team accountable for Project Context
{{CONTEXT_DIR}}             Project Context directory, default docs/project
```

Required project-provided inputs（项目必须自行提供的输入）: identity, workspace shape, subsystem inventory, data ownership, and hard constraints. A template cannot infer these.

## Conformance（符合性判定）

A Project Context directory conforms when:

1. All four required documents exist.
2. Each carries the common header with a declared `Owner` and `Status`.
3. Each contains its required sections.
4. No document restates Harness Core workflow, governance, or recovery rules.
5. During a compatibility phase, each document declares its `Source References`.

Non-conformance is a documentation defect, not a runtime failure. It is fixed by correcting the document, never by weakening this contract.
