---
description: Regenerate the boochtek plugin from canonical ~/.config/ai sources
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

# Publish to Plugin

Regenerate the published **boochtek** plugin from canonical sources in
`~/.config/ai/`. Content flows **one way — canonical → plugin**. This command
never edits canonical files and never creates symlinks back into the plugin.

- **Source of truth:** `~/.config/ai/{commands,skills}` — real files, read by
  every harness (Claude Code, OpenCode, Codex) via symlinks.
- **Published artifact:** the `boochtek/ai-skills` repo, developed at
  `~/Work/Code/ai-skills`, installed by others via the marketplace.
- **Selection:** an item ships if and only if its frontmatter has `publish: true`.
- **Marketplace clone** (`~/.config/claude/plugins/marketplaces/boochtek`) is a
  Claude-Code-managed, gitignored checkout — only for testing installs, never a
  source and never a commit target.

ARGUMENTS: $ARGUMENTS

## 1. Optional argument

With no argument, regenerate the entire publish set (step 3).

If given an item (`command <name>`, `skill <name>`, or a path), treat it as
"make sure this ships": if its canonical frontmatter lacks `publish: true`, show
the file and ask to add the marker, then continue with a full regenerate.

## 2. Ensure the dev clone

```bash
test -d ~/Work/Code/ai-skills \
  || git clone git@github.com:boochtek/ai-skills.git ~/Work/Code/ai-skills
git -C ~/Work/Code/ai-skills switch main
git -C ~/Work/Code/ai-skills pull --ff-only
```

If the dev clone's working tree is dirty, stop and let the user resolve it first.

## 3. Determine the publish set

Find canonical items whose frontmatter contains `publish: true`:

```bash
rg -l '^publish: true$' ~/.config/ai/commands ~/.config/ai/skills
```

- Command → `~/.config/ai/commands/<name>.md`
- Skill → `~/.config/ai/skills/<name>/` (the whole directory)

## 4. Quality review

- Skills: use the `plugin-dev:skill-reviewer` agent.
- Commands: confirm frontmatter has a `description`; check clarity and structure.

Report any issues and ask before continuing.

## 5. Sync into the plugin (canonical → dev clone)

Copy each published item into the dev clone as a **real file**:

- Command → `plugins/boochtek/commands/<name>.md`
- Skill → `plugins/boochtek/skills/<name>/` (copy the entire directory with
  `cp -R`, including any `scripts/` or other assets)

Then remove the source-only marker from each **copy** with the Edit tool — delete
the `publish: true` line. Never edit the canonical original.

Reconcile deletions: remove any plugin command/skill that is **no longer** in the
publish set, so unpublishing works. List everything you would delete and confirm
before removing it.

## 6. Update manifests and README

- `plugins/boochtek/.claude-plugin/plugin.json` — bump the version if the change
  warrants it (a version bump is what makes Claude Code re-install).
- `.claude-plugin/marketplace.json` — keep in sync.
- `README.md` — regenerate the Commands and Skills lists from the publish set.

## 7. Shipping manifest

Print what will ship — items added, removed, and updated since the last publish
(`git -C ~/Work/Code/ai-skills status` plus a short diff summary). Ask the user to
review before committing.

## 8. Commit and push

Invoke the `commits` skill. Commit in the dev clone with an AI attribution trailer
(get the tool version from `claude --version`). **Push only after the user
confirms** — publishing is outward-facing.

```bash
git -C ~/Work/Code/ai-skills add -A
git -C ~/Work/Code/ai-skills commit -m "<message>"
git -C ~/Work/Code/ai-skills push
```

## 9. Test the install

In Claude Code, run `/plugin marketplace update boochtek` (pulls the pushed plugin
into the gitignored marketplace clone), then verify the commands/skills load.
Other harnesses read `~/.config/ai/` directly, so they need nothing.

## Never

- Never create symlinks from `~/.config/ai/` into the plugin.
- Never edit, move, or delete canonical files from this command.
- Never commit to, or treat as a source, the marketplace clone.
