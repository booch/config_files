# 1. Canonical AI commands/skills in ~/.config/ai, plugin as a generated copy

Date: 2026-06-16

## Status

Accepted

## Context

AI commands and skills must work across multiple harnesses — Claude Code,
OpenCode, and Codex — not just Claude Code. Each harness already reads
`~/.config/ai/{commands,skills}` and `AGENTS.md` through symlinks from its own
config directory.

A curated subset is also published for other people as the `boochtek/ai-skills`
Claude Code plugin. The previous setup made the Claude Code plugin the source of
truth: `/publish-to-plugin` moved a file into the plugin and left a symlink
behind, and the plugin's marketplace clone was tracked in the config_files repo
as a git submodule. That inverted ownership — Claude-Code-specific storage
became canonical for harness-neutral content — caused submodule gitlink churn
and dirty-submodule noise on every marketplace update, and produced dangling
symlinks when the plugin was restructured (e.g. `new-project`, recovered from the
installed plugin cache).

## Decision

`~/.config/ai/` is the single, harness-neutral source of truth: real Markdown
files, consumed by every harness via symlinks.

The Claude Code plugin is a generated **downstream** artifact. `/publish-to-plugin`
copies items marked `publish: true` from canonical into the dev clone at
`~/Work/Code/ai-skills`, strips the marker, and (on confirmation) commits and
pushes. Content flows one way — canonical → plugin — never back.

The marketplace clone (`~/.config/claude/plugins/marketplaces/boochtek`) is a
Claude-Code-managed, gitignored checkout used only to test installs. It is not a
submodule and not a commit target. GitHub remains the source of record;
`install.sh` re-adds the marketplace on a new machine.

## Consequences

- **Easier:** one source of truth; no symlink inversions; no submodule
  bookkeeping; the same content serves all harnesses; publishing is an explicit,
  auditable copy gated by `publish: true` (so personal items stay private by
  default).
- **Harder:** a fresh machine must re-add the marketplace (handled by
  `install.sh`); publishing requires running `/publish-to-plugin` rather than
  editing in place; plugin-only content (a skill never added to canonical, e.g.
  `lang-elixir`) must be pulled into canonical or it will not be regenerated.
- The old inverting `/publish-to-plugin` and `sync-to-global.sh` are retired.
