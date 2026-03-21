---
description: Sync markdownlint settings from ~/.config/markdown/markdownlint.yaml into CLI2 and Zed, with dry-run support
allowed-tools: Read, Grep, Write, Edit, Bash
---

# Markdownlint Sync Command

Sync markdownlint settings from `~/.config/markdown/markdownlint.yaml` into:

- `~/.config/markdown/markdownlint-cli2.jsonc`
- `~/.config/zed/settings.json` at `lsp.markdownlint.settings`

`~/.config/markdown/markdownlint.yaml` is the SINGLE SOURCE OF TRUTH. Everything else is derived from it.

## Usage

- `/markdownlint-sync` - Apply the sync
- `/markdownlint-sync --dry-run` - Preview the exact changes without writing files

## Rules

- Treat `~/.config/markdown/markdownlint.yaml` as the only source of truth for markdownlint rule settings.
- If the YAML is invalid, ambiguous, or not a top-level mapping of rule keys to values, stop and explain the problem instead of guessing.
- Preserve comments in the YAML source file.
- Preserve unrelated settings in both target files exactly where practical.
- Only update values derived from the YAML source.
- Prefer rule keys exactly as they appear in the YAML source.
- The command must be idempotent: a second run with no source changes should make no further edits.

## Required Warnings

Make the warnings hard to miss. Strong wording matters more than exact phrasing.

### `markdownlint.yaml`

At the very top, ensure a banner comment that clearly says:

- `WARNING:`
- `SINGLE SOURCE OF TRUTH`
- This file controls markdownlint settings.
- After ANY change, run `codex /markdownlint-sync`.

### `markdownlint-cli2.jsonc`

At the very top, ensure a banner comment that clearly says:

- `WARNING:`
- `DO NOT EDIT HERE`
- This file is synced from `~/.config/markdown/markdownlint.yaml`.
- This file is NOT the source of truth.
- Make changes in the source file, then run `codex /markdownlint-sync`.

### `zed/settings.json`

Immediately above `lsp.markdownlint.settings`, ensure a banner comment that clearly says:

- `WARNING:`
- `DO NOT EDIT HERE`
- This section is synced from `~/.config/markdown/markdownlint.yaml`.
- This section is NOT the source of truth.
- Make changes in the source file, then run `codex /markdownlint-sync`.

## Workflow

1. Read:
   - `~/.config/markdown/markdownlint.yaml`
   - `~/.config/markdown/markdownlint-cli2.jsonc`
   - `~/.config/zed/settings.json`

2. Derive the desired rule object from the YAML top-level mapping.
   - Preserve booleans, numbers, strings, arrays, and nested mappings faithfully.
   - Do not invent extra rules.

3. Update `~/.config/markdown/markdownlint.yaml`.
   - Add or replace only the top warning banner.
   - Preserve the rest of the file, including existing comments.

4. Update `~/.config/markdown/markdownlint-cli2.jsonc`.
   - Add or replace only the top warning banner.
   - Sync only the `"config"` object from the YAML-derived rule object.
   - Remove stale rule keys from `"config"` when they no longer exist in YAML.
   - Preserve existing non-rule top-level keys such as `customRules`, `fix`, `frontMatter`, `gitignore`, `globs`, `ignores`, `markdownItPlugins`, `modulePaths`, `noBanner`, `noInlineConfig`, `noProgress`, `outputFormatters`, and `showFound`.
   - If exact comment preservation inside `"config"` is impractical, it is acceptable to rewrite only that object.

5. Update `~/.config/zed/settings.json`.
   - Ensure `lsp` exists.
   - Ensure `lsp.markdownlint` exists.
   - Add or replace `lsp.markdownlint.settings` with the YAML-derived rule object.
   - Preserve unrelated Zed settings exactly.
   - Preserve unrelated `lsp.markdownlint` settings.
   - Add or replace the warning comment immediately above `settings`.

6. Support dry-run mode.
   - With `--dry-run`, write nothing.
   - Show a concise preview of what would change in each file.
   - If nothing would change, say so.

7. Verify.
   - The three warning banners are present.
   - The YAML-derived rule object matches CLI2 `"config"`.
   - The YAML-derived rule object matches Zed `lsp.markdownlint.settings`.
   - A second run would be a no-op.

8. Summarize.
   - Say whether this was a dry-run or a write.
   - List changed files.
   - Mention any removed stale keys.
   - Mention any unavoidable formatting or comment normalization in target files.

## Approach

- Prefer a small one-off script or minimal structural edits.
- Touch only:
  - the YAML top banner
  - the CLI2 top banner
  - the CLI2 `"config"` object
  - the Zed warning comment above `settings`
  - the Zed `lsp.markdownlint.settings` object
- If `lsp` or `lsp.markdownlint` is missing, create the minimum required structure.
- Replace weaker or outdated sync warnings with the stronger warnings above.
- Do not silently keep target-only rule keys unless they are clearly intentional.
