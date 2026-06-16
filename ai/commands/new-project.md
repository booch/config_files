---
description: Collaboratively create a new project with scaffolding, AI config, docs, and GitHub repo
---

# New Project

Collaboratively discover what the user wants to build, then scaffold a complete project.

The user may provide upfront context (e.g., `/new-project An Elixir library for parsing MIDI files`). Use whatever they provide; ask about the rest.

## Phase 1: Discovery

Have a collaborative discussion — not an interrogation. Understand:

- **What** the project does and **why** it exists
- **Who** it's for (audience, users)
- **Goals** and **non-goals**
- **Language/framework** — consult `HUMAN.md` for preferences; suggest options from their preferred languages
- **Key features** (high-level, not exhaustive)
- **Project name** — collaborate; prefer short, memorable, kebab-case; offer suggestions
- **Directory location** — where it should live (e.g., `~/Work/Code/`, `~/Personal/Writing/`)
- **GitHub org** or other upstream source

### Context Detection

Before asking questions:

- Check if the current directory already has project structure (`.git/`, `mix.exs`, `Gemfile`, `package.json`, etc.). If so, ask if the user wants to enhance the existing project.
- Check if a project name can be derived from the current directory path.

### Research

Once the language/framework is chosen:

- Do web research on current best practices for scaffolding that ecosystem.
- Check for any language/framework-specific skills and consult them for opinions on project structure.

## Phase 2: Plan & Approve

Present the complete scaffolding plan:

- Project name and directory path
- GitHub repo: org, public/private (default **private**; recommend public with justification if appropriate)
- Language/framework and version (pinned in `.mise.toml`)
- Directory structure overview
- Files to be created
- AI plugins to install
- Any existing files that will be modified (brownfield)

**Wait for explicit approval before creating anything.**

## Phase 3: Scaffold

Create the project in this order:

1. Create directory (if needed)
2. `git init`
3. Language-specific scaffolding — run the appropriate tool (`mix new`, `rails new`, `bun init`, `hugo new site`, `bundle gem`, etc.)
4. Standard files (see below)
5. AI configuration (see below)
6. Initial commit: `Initial project scaffold`
7. Create GitHub repo via `gh repo create`, push
8. Create a GitHub issue for the first piece of real work
9. Offer to open in editor (`zed .`)

### Standard Files

Generate all content contextually — no templates. The AI decides what's appropriate based on the project.

**Always create:**

- `README.md` — see README Structure below
- `CHANGELOG.md` — Keep a Changelog format, initialized with `## [Unreleased]`
- `LICENSE.md` — ask user; default MIT for public, proprietary header for private
- `.gitignore` — language-appropriate plus common OS/editor entries
- `.editorconfig` — indent style/size, trailing whitespace, final newline
- `.mise.toml` — pin language/runtime versions
- `Makefile` — see Makefile section below
- `.github/workflows/ci.yml` — GitHub Actions running `make ci`
- Linting config — language-appropriate (RuboCop, Credo, Biome, shellcheck, etc.)
- Testing framework config — language-appropriate (RSpec, ExUnit, Vitest, etc.)

**Documentation:**

- `docs/` — LLM wiki; documentation-as-context that improves as work progresses
- `docs/sources/` — immutable reference material (specs, RFCs, research)
- `docs/adr/` — Architecture Decision Records
- `docs/adr/001-project-creation.md` — documents initial tech choices and rationale (sets the example for future ADRs)

**AI configuration:**

- `.ai/` — agent-agnostic AI config directory
- `.ai/AGENTS.md` — project-specific AI instructions (see AGENTS.md Structure below)
- `.ai/context.md` — session continuity / handoff state (initialize empty with a header)
- `.ai/learnings.md` — project-specific learnings (initialize empty with a header)

**AI tool symlinks** — `.ai/AGENTS.md` is the single source of truth; symlinks make it discoverable by all tools:

| Tool | Symlink | Notes |
|------|---------|-------|
| Claude Code | `.claude/ -> .ai/` (dir) + `.ai/CLAUDE.md -> AGENTS.md` (file) | Claude looks for `.claude/CLAUDE.md` |
| Cursor | `.cursorrules -> .ai/AGENTS.md` | Legacy path; still widely supported |
| GitHub Copilot | `.github/copilot-instructions.md -> ../.ai/AGENTS.md` | Goes inside `.github/` dir |
| Codex + OpenCode | `AGENTS.md -> .ai/AGENTS.md` | Both look for `AGENTS.md` in project root |

Create only the symlinks for tools the user actively uses. Always create the Claude Code symlinks.
All symlinks should be relative paths so they work when the repo is cloned to different locations.

**Public repos also get:**

- `CONTRIBUTING.md`
- `SECURITY.md` (GitHub recognizes this specially)

### README Structure

Suggested sections (adjust based on project complexity):

```markdown
# Project Name

One-line description.

## Goals

What this project aims to achieve and why it exists.

## Non-Goals

What this project explicitly does NOT try to do (prevents scope creep).

## Getting Started

Prerequisites, installation, basic usage.

## Development

How to set up for development, run tests, lint.

## Architecture

Brief overview (or link to docs/architecture.md for complex projects).

## License
```

### AGENTS.md Structure

Project-specific AI instructions. Capture insights from the discovery conversation — purpose, goals, and the "why" behind decisions.

```markdown
# [Project Name]

[1-2 sentence project description and purpose]

## Architecture

[Brief overview of project structure and key components]

## Development Workflow

- Follow TDD: write tests first, then implement
- Follow the `documentation` skill: update docs with code changes, use ADRs for decisions
- Run `make ci` before committing

## Conventions

[Language-specific conventions, naming patterns, etc.]

## Key Decisions

See `docs/adr/` for architecture decision records.

## Documentation

Documentation lives in `docs/` and serves as the project's knowledge base.
- Update docs alongside code changes — never as separate commits
- Add ADRs for any significant technical decision
- Keep `docs/sources/` for immutable reference material
- Follow the `documentation` skill for full guidance
```

### Makefile

Self-documenting with standard targets:

- `help` (default) — grep-based self-documenting pattern
- `test` — language-appropriate test command
- `specs` — alias for `test`
- `lint` — language-appropriate linters
- `build` — language-appropriate build
- `clean` — remove build artifacts
- `ci` — `lint` + `test`
- `publish` — release the project
- `version` — show current version

### ADR Format (Michael Nygard)

```markdown
# N. Title

Date: YYYY-MM-DD

## Status

Accepted | Superseded by [N] | Deprecated

## Context

What issue motivates this decision? What forces are at play?

## Decision

What change are we making?

## Consequences

What becomes easier or harder because of this change?
```

### AI Plugin Installation

Install these Claude Code plugins for the project:

- **Superpowers** — development workflow (TDD, code review, brainstorming, debugging)
- **BoochTek** — learning skill, documentation skill
- **Language-specific skills** — e.g., Elixir skills for Elixir projects

## Phase 4: Handoff

Summarize what was created:

- Directory path and GitHub URL
- Overview of project structure
- Suggested next steps (e.g., "run `/tdd` to start implementing the first feature")
