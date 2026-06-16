---
description: Remember something for future sessions (alias for /learn)
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Remember Command

This is an alias for `/learn`. It persists insights to improve future AI agent behavior.

## Usage

- `/remember <insight>` — Remember a specific insight
- `/remember` — Interactive mode

## Examples

- `/remember Grammy requires updating before Stone when changing parser rules`
- `/remember Craig prefers tests grouped by behavior, not by method`
- `/remember The visitor pattern is in lib/stone/visitor.rb`

## How It Works

This command invokes `/learn` with the provided argument. See `/learn` for full documentation.

The distinction:

- `/retro` — Structured session review that identifies learnings
- `/learn` — Process and persist identified learnings
- `/remember` — Quick way to persist a single insight

Typical flow:

1. End of session: `/retro` to review
2. `/learn --from-retro` to persist all learnings
3. Or during session: `/remember <quick insight>` for ad-hoc learning
