---
name: markdown
description: Writing and editing Markdown files. Use when creating or modifying .md files to ensure proper formatting.
---

# Markdown Skill

## Formatting Checks

Run `make markdownlint` to check for proper Markdown formatting.

## Key Rules

- There must be a blank line before and after any list (ordered or unordered).
- There must be a blank line before and after fenced code blocks.
- Indent nested list items 4 spaces (MD007), not 2.
- Table separator rows use spaced pipes: `| --- | --- |` (MD060).
- No hard tabs, even inside fenced code blocks (MD010).
  For a Makefile example, use one-line `target: ; recipe` rules.
- Code spans must not start or end with a space (MD038).
