# Design: `/new-project` Command

**Date:** 2026-04-15
**Status:** Approved
**Approach:** Workflow guide — define constraints and workflow, delegate content generation to AI agent

## Overview

`/new-project` is a command that collaboratively discovers what the user wants to build, then scaffolds a complete, ready-to-code project, with an appropriate structure, configuration, and tools.

## Phases

### Phase 1: Discovery (Collaborative)

AI has a discussion with the user to understand:

- **What** the project does and **why** it exists
- **Who** it's for (audience, users)
- **Goals** (and non-goals) for the project
- **Language/framework** choice (consult HUMAN.md for preferences; suggest options)
- **Key features** or capabilities (high-level)
- **Project name** — collaborate on naming; prefer short, memorable, kebab-case; offer suggestions
- **Directory location** — where it should live locally (eg: `~/Work/Code/`, `~/Personal/Writing/`)
- **GitHub org** or other "upstream" source

**Context detection:**

- Determine if name of the project can be derived from current directory path
- Determine if we already have existing structure in current directory

- Accept optional upfront context: `/new-project An Elixir library for parsing MIDI files` — skip questions the description already answers

**Research:**
- Do web research on current best practices for scaffolding the chosen language/framework
- Consult any language/framework-specific skills (eg, Elixir skill, Ruby skill) for scaffolding opinions

### Phase 2: Plan & Approve

Present a complete scaffolding plan for approval:

- Project name and directory path
- GitHub repo (org, public/private — default private; AI may recommend public with justification)
- Language/framework and version (pinned in `.mise.toml`)
- Directory structure overview
- Files to be created
- AI plugins to install
- Whether any existing files will be modified (brownfield)

**Single approval checkpoint:** User approves the plan (including public/private decision) before any files are created.

### Phase 3: Scaffold

Create the project. Order matters:

1. **Create directory** (if it doesn't exist)
2. **Initialize git** — `git init`
3. **Language-specific scaffolding** — run the appropriate tool (`mix new`, `rails new`, `bun init`, `hugo new site`, `bundle gem`, etc.) with sensible defaults
4. **Enhance with standard files** (see Standard Files below)
5. **AI configuration** (see AI Setup below)
6. **Initial commit** — commit everything with message: `Initial project scaffold`
7. **Create GitHub repo** — `gh repo create`, push
8. **Create first issue** — a GitHub issue for the first piece of real work
9. **Open in editor** — offer to `zed .`

### Phase 4: Handoff

Summarize what was created and suggest next steps:

- Directory path and GitHub URL
- What's in the project
- Suggested first actions (e.g., "run `/tdd` to start implementing the first feature")

## Standard Files

Every project gets these (AI generates content contextually, no templates):

### Always Created

| File | Purpose |
|------|---------|
| `README.md` | Project overview with sections (see README Structure) |
| `CHANGELOG.md` | Keep a Changelog format, initialized with `## [Unreleased]` |
| `LICENSE` | Ask user; default MIT for public, proprietary header for private |
| `.gitignore` | Language-appropriate, plus common OS/editor entries |
| `.editorconfig` | Consistent formatting (indent style/size, trailing whitespace, final newline) |
| `.mise.toml` | Pin language/runtime versions |
| `Makefile` | Self-documenting with standard targets (see Makefile section) |
| `.github/workflows/ci.yml` | GitHub Actions running `make ci` |

### Documentation

| File/Dir | Purpose |
|----------|---------|
| `docs/` | LLM wiki — documentation-as-context, improved as work progresses |
| `docs/sources/` | Immutable reference material (specs, RFCs, research) |
| `docs/adr/` | Architecture Decision Records |
| `docs/adr/001-project-creation.md` | ADR 0: documents initial tech choices and rationale |
| `docs/architecture.md` | High-level system overview (created once structure emerges) |

### AI Configuration

| File/Dir | Purpose |
|----------|---------|
| `.ai/` | Agent-agnostic AI config directory |
| `.ai/AGENTS.md` | Project-specific AI instructions (see AGENTS.md Structure) |
| `.ai/context.md` | Session continuity / handoff state |
| `.ai/learnings.md` | Project-specific learnings |
| `.claude` → `.ai/` | Symlink for Claude Code compatibility |

### Language-Specific

Created based on the chosen language/framework. Examples:

- **Elixir:** `mix.exs`, `lib/`, `test/`, `.formatter.exs`, `.credo.exs`
- **Ruby:** `Gemfile`, `lib/`, `spec/`, `.rubocop.yml`
- **TypeScript:** `package.json` (bun), `src/`, `test/`, `biome.json`
- **Hugo:** `hugo.toml`, `content/`, `layouts/`, `static/`
- **Bash:** `bin/`, `lib/`, `test/`, `shellcheck` config

### Conditionally Created

| File | When |
|------|------|
| `CONTRIBUTING.md` | Public repos |
| `SECURITY.md` | Public repos (GitHub recognizes this specially) |
| `CODE_OF_CONDUCT.md` | Public repos, if user wants one |

## README Structure

Suggested sections (AI adjusts based on project complexity):

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

## AGENTS.md Structure

Project-specific AI instructions:

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

## Makefile

Self-documenting Makefile with these standard targets:

```makefile
.DEFAULT_GOAL := help
.PHONY: help test specs lint build clean publish version ci

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

test: ## Run tests
	[language-appropriate test command]

specs: test ## Alias for test

lint: ## Run linters
	[language-appropriate lint command]

build: ## Build the project
	[language-appropriate build command]

clean: ## Remove build artifacts
	[language-appropriate clean command]

ci: lint test ## Run CI checks (lint + test)

publish: ## Publish/release the project
	[language-appropriate publish command]

version: ## Show current version
	[language-appropriate version command]
```

## AI Plugin Installation

Default plugins installed via Claude Code:

| Plugin | Purpose |
|--------|---------|
| Superpowers | Development workflow (TDD, code review, brainstorming, debugging) |
| BoochTek learn | Cross-session learning and knowledge persistence |
| Language-specific skills | E.g., Elixir skills for Elixir projects |
| Documentation skill | Docs-as-code discipline (from boochtek plugin) |

## ADR Format

ADRs use the Michael Nygard template:

```markdown
# N. Title

Date: YYYY-MM-DD

## Status

Accepted | Superseded by [N] | Deprecated

## Context

What is the issue that we're seeing that is motivating this decision?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?
```

## Dependencies

- `documentation` skill in boochtek plugin (referenced from generated AGENTS.md)
- `gh` CLI (for GitHub repo creation)
- `mise` (for version pinning)
- Language-specific tools (`mix`, `bundle`, `bun`, `hugo`, etc.)
