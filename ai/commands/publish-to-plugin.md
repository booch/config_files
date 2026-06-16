---
description: Migrate a local command or skill to the boochtek plugin for publishing
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
---

# Publish to Plugin

Migrate a local command or skill from ~/.config/ai/ to the boochtek plugin,
replacing the original with a symlink back, and commit both repos.

ARGUMENTS: $ARGUMENTS

## 1. Parse Arguments

Normalize the argument to determine type and name:

| Input examples | Type | Name |
|---|---|---|
| `skill make-bed`, `skill/make-bed`, `skills/make-bed` | skill | make-bed |
| `command morning`, `command/morning`, `commands/morning` | command | morning |
| `skills/make-bed/SKILL.md` | skill | make-bed |
| `commands/morning.md` | command | morning |

Strip trailing `.md` or `/SKILL.md`. Singularize `skills` → `skill`, `commands` → `command`.
If arguments are missing or ambiguous, ask.

## 2. Validate

Set these paths based on type:

**Command:**
- Source: `~/.config/ai/commands/<name>.md`
- Destination: `~/.config/claude/plugins/marketplaces/boochtek/plugins/boochtek/commands/<name>.md`
- Symlink target (relative): `../../claude/plugins/marketplaces/boochtek/plugins/boochtek/commands/<name>.md`

**Skill:**
- Source: `~/.config/ai/skills/<name>/SKILL.md`
- Destination: `~/.config/claude/plugins/marketplaces/boochtek/plugins/boochtek/skills/<name>/SKILL.md`
- Symlink target (relative): `../../../claude/plugins/marketplaces/boochtek/plugins/boochtek/skills/<name>/SKILL.md`

Check:
- Source file exists
- Source is NOT already a symlink (already migrated)
- Destination does NOT already exist in the plugin (would overwrite)

If any check fails, report and stop.

## 3. Quality Review

Before migrating, review the content:

- **For skills**: Use the `plugin-dev:skill-reviewer` agent to review the skill
- **For commands**: Check that frontmatter has a `description` field, and review structure and clarity

Report any issues found. Ask user to confirm before proceeding.

## 4. Migrate

Use the Bash tool for the filesystem operations:

**Command:**
```bash
cp ~/.config/ai/commands/<name>.md <destination>
rm ~/.config/ai/commands/<name>.md
ln -s <symlink-target> ~/.config/ai/commands/<name>.md
```

**Skill:**
```bash
mkdir -p <destination-dir>
cp ~/.config/ai/skills/<name>/SKILL.md <destination>
rm ~/.config/ai/skills/<name>/SKILL.md
ln -s <symlink-target> ~/.config/ai/skills/<name>/SKILL.md
```

Verify the symlink resolves correctly by reading through it.

## 5. Commit boochtek repo

```bash
git -C ~/.config/claude/plugins/marketplaces/boochtek add <type>s/<name>
git -C ~/.config/claude/plugins/marketplaces/boochtek commit -m "Add /<name> <type> for publishing"
```

The post-commit hook runs sync-to-global.sh automatically.

Include appropriate AI attribution trailers (check `claude --version` for the version).

## 6. Commit ~/.config repo

```bash
git -C ~/.config add ai/<type>s/<name> claude/plugins/marketplaces/boochtek
git -C ~/.config commit -m "Migrate <name> <type> to boochtek plugin"
```

Include appropriate AI attribution trailers.

## 7. Summary

Report:
- What was migrated (file path from → to)
- Symlink created
- Commits made (with short SHAs) in both repos
- Any quality review notes
