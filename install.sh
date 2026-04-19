#!/bin/bash

# Make certain we're in the directory containing this file.
cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || (echo "$(tput setaf 1)Could not change to script directory$(tput sgr0)" && exit)

# Get full path to the directory.
CWD="$(pwd)"

TODAY="$(date +%Y%m%d)"

# Symlink a file, backing up any existing regular file.
# Existing symlinks are replaced silently (idempotent).
link_file() {
    src="$1"
    dst="$2"
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        if [ ! -e "${dst}-${TODAY}" ]; then
            mv "$dst" "${dst}-${TODAY}"
        else
            rm -rf "$dst"
        fi
    fi
    ln -s "$src" "$dst"
}

# Symlink a directory, backing up any existing directory.
# We'd use `ln -sfT` on Linux, if we didn't want the backups.
# According to the macOS man page, `ln -sfF` should work the same, but it does not.
link_dir() {
    link_file "$1" "$2"
}

# Migrate a home dotdir (e.g. ~/.gemini) into ~/.config, then symlink back.
# Preserves existing contents (auth state, etc.) during migration.
migrate_to_config() {
    local name="$1"
    local config_dir="$CWD/$name"
    local home_dir="$HOME/.$name"
    mkdir -p "$config_dir"
    # If the home dotdir is a real directory (not already a symlink), move its contents.
    if [ -d "$home_dir" ] && [ ! -L "$home_dir" ]; then
        if [ -n "$(ls -A "$home_dir" 2>/dev/null)" ]; then
            cp -a "$home_dir"/. "$config_dir"/
        fi
    fi
    link_dir "$config_dir" "$home_dir"
}

# Create default $XDG_DATA_HOME, $XDG_STATE_HOME, and $XDG_CACHE_HOME.
# See https://specifications.freedesktop.org/basedir-spec/.
mkdir -p "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"
chmod 700 "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"

# Link files to where they "belong". Hopefully some day, all commands will support `~/.config` or `$XDG_CONFIG_HOME`.
link_file "$CWD/ack/ackrc" "$HOME/.ackrc"

link_file "$CWD/zsh/zshrc" "$HOME/.zshrc"
link_dir "$CWD/zsh" "$HOME/.zsh"

link_file "$CWD/bash/aliases" "$HOME/.bash_aliases"
link_file "$CWD/bash/bash_logout" "$HOME/.bash_logout"
link_file "$CWD/bash/bash_profile" "$HOME/.bash_profile"
link_file "$CWD/bash/bashrc" "$HOME/.bashrc"
link_file "$CWD/bash/profile" "$HOME/.profile"
link_dir "$CWD/bash/profile.d" "$HOME/.profile.d"
link_file "$CWD/bash/inputrc" "$HOME/.inputrc"

link_dir "$CWD/ruby/bundler" "$HOME/.bundle"
link_file "$CWD/ruby/gemrc" "$HOME/.gemrc"
link_file "$CWD/ruby/pryrc" "$HOME/.pryrc"
link_file "$CWD/ruby/aprc" "$HOME/.aprc"
link_file "$CWD/ruby/railsrc" "$HOME/.railsrc"
link_file "$CWD/ruby/ruby-version" "$HOME/.ruby-version"
link_file "$CWD/ruby/rubocop.yml" "$HOME/.rubocop.yml"
link_file "$CWD/ruby/default-gems" "$HOME/.default-gems"

# NOTE: Global elintrc files are deprecated and give a warning.
# link_file "$CWD/js/eslintrc.yml"             "$HOME/.eslintrc.yml"
link_file "$CWD/js/jscsrc" "$HOME/.jscsrc"
link_file "$CWD/js/jshintrc" "$HOME/.jshintrc"

link_file "$CWD/racket/racketrc" "$HOME/.racketrc"

link_file "$CWD/markdown/markdownlint.yaml" "$HOME/.markdownlint.yaml"
link_file "$CWD/markdown/markdownlint-cli2.jsonc" "$HOME/.markdownlint-cli2.jsonc"

link_file "$CWD/ctags" "$HOME/.ctags"

link_file "$CWD/finicky/finicky.js" "$HOME/.finicky.js"

link_dir "$CWD/docker" "$HOME/.docker"

link_dir "$CWD/mc" "$HOME/.mc"

link_file "$CWD/nano/nanorc" "$HOME/.nanorc"
link_dir "$CWD/nano" "$HOME/.nano"

link_file "$CWD/less/lessfilter" "$HOME/.local/bin/lessfilter"
link_file "$CWD/vim/vimrc" "$HOME/.vimrc"
link_dir "$CWD/vim" "$HOME/.vim"

link_dir "$CWD/atom" "$HOME/.atom"

link_file "$CWD/postgresql/psqlrc" "$HOME/.psqlrc"

link_dir "$CWD/usql" "$HOME/Library/Application Support/usql"

## AI tools.
# Symlink home dotdirs into ~/.config for tools that don't respect XDG.
migrate_to_config "claude"
migrate_to_config "gemini"
migrate_to_config "copilot"
migrate_to_config "codex"

# Sync AI agent instructions from ~/.config/ai to tool-specific locations.
# Source of truth: ~/.config/ai/AGENTS.md
AI_DIR="$CWD/ai"

# Claude Code: expects CLAUDE.md, plus agents/, skills/, commands/ directories.
link_file "$AI_DIR/AGENTS.md" "$CWD/claude/CLAUDE.md"
link_dir "$AI_DIR/agents" "$CWD/claude/agents"
link_dir "$AI_DIR/skills" "$CWD/claude/skills"
link_dir "$AI_DIR/commands" "$CWD/claude/commands"

# OpenCode: uses AGENTS.md natively, plus skills/ via Superpowers plugin.
link_file "$AI_DIR/AGENTS.md" "$CWD/opencode/AGENTS.md"
link_dir "$AI_DIR/skills" "$CWD/opencode/skills"

# GitHub Copilot CLI: reads copilot-instructions.md from ~/.copilot/.
link_file "$AI_DIR/AGENTS.md" "$CWD/copilot/copilot-instructions.md"

# GitHub Copilot (VS Code): reads from instructions directory.
# NOTE: VS Code requires absolute paths in settings.json (no ~ or ${env:HOME}).
#       The codeGeneration.instructions setting should reference:
#       /Users/<you>/.config/github-copilot/instructions/agents.md
mkdir -p "$CWD/github-copilot/instructions"
link_file "$AI_DIR/AGENTS.md" "$CWD/github-copilot/instructions/agents.md"

# Windsurf: global rules live inside ~/.codeium (mixed state, can't relocate).
mkdir -p "$HOME/.codeium/windsurf/memories"
link_file "$AI_DIR/AGENTS.md" "$HOME/.codeium/windsurf/memories/global_rules.md"

# Gemini CLI: expects GEMINI.md in ~/.gemini/ (symlinked to ~/.config/gemini/).
link_file "$AI_DIR/AGENTS.md" "$CWD/gemini/GEMINI.md"

# Codex: uses AGENTS.md in ~/.codex/ (symlinked to ~/.config/codex/).
link_file "$AI_DIR/AGENTS.md" "$CWD/codex/AGENTS.md"

# Zed: uses a different prompt structure. Manual setup may be needed.
# Consider copying relevant prompts to ~/.config/zed/prompts/.

# Claude Code: install plugin marketplaces and plugins.
# Boochtek marketplace is a git submodule, not managed here.
if command -v claude >/dev/null; then
    claude plugins marketplace add anthropics/claude-plugins-official
    claude plugins install agent-sdk-dev@claude-plugins-official
    claude plugins install claude-code-setup@claude-plugins-official
    claude plugins install claude-md-management@claude-plugins-official
    claude plugins install code-review@claude-plugins-official
    claude plugins install code-simplifier@claude-plugins-official
    claude plugins install commit-commands@claude-plugins-official
    claude plugins install feature-dev@claude-plugins-official
    claude plugins install frontend-design@claude-plugins-official
    claude plugins install github@claude-plugins-official
    claude plugins install gitlab@claude-plugins-official
    claude plugins install hookify@claude-plugins-official
    claude plugins install huggingface-skills@claude-plugins-official
    claude plugins install kotlin-lsp@claude-plugins-official
    claude plugins install linear@claude-plugins-official
    claude plugins install lua-lsp@claude-plugins-official
    claude plugins install playground@claude-plugins-official
    claude plugins install playwright@claude-plugins-official
    claude plugins install plugin-dev@claude-plugins-official
    claude plugins install pr-review-toolkit@claude-plugins-official
    claude plugins install pyright-lsp@claude-plugins-official
    claude plugins install ruby-lsp@claude-plugins-official
    claude plugins install security-guidance@claude-plugins-official
    claude plugins install skill-creator@claude-plugins-official
    claude plugins install slack@claude-plugins-official
    claude plugins install superpowers@claude-plugins-official
    claude plugins install swift-lsp@claude-plugins-official
    claude plugins install typescript-lsp@claude-plugins-official
    claude plugins install vercel@claude-plugins-official

    claude plugins marketplace add anthropics/skills
    claude plugins install claude-api@anthropic-agent-skills
    claude plugins install document-skills@anthropic-agent-skills
    claude plugins install example-skills@anthropic-agent-skills

    claude plugins marketplace add obra/superpowers-marketplace
    claude plugins install claude-session-driver@superpowers-marketplace
    claude plugins install double-shot-latte@superpowers-marketplace
    claude plugins install elements-of-style@superpowers-marketplace
    claude plugins install episodic-memory@superpowers-marketplace
    claude plugins install superpowers-developing-for-claude-code@superpowers-marketplace
    claude plugins install superpowers-lab@superpowers-marketplace
    claude plugins install superpowers@superpowers-marketplace

    claude plugins marketplace add internetarchive/internet-archive-skills
    claude plugins install ia@internet-archive-skills

    claude plugins marketplace add thedotmack/claude-mem
    claude plugins install claude-mem@thedotmack

    claude plugins marketplace add mksglu/context-mode
    claude plugins install context-mode@context-mode

    claude plugins marketplace add Lum1104/Understand-Anything
    claude plugins install understand-anything@understand-anything

    claude plugins marketplace add jarrodwatts/claude-hud
    claude plugins install claude-hud@claude-hud

    claude plugins marketplace add kepano/obsidian-skills
    claude plugins install obsidian@obsidian-skills

    claude plugins marketplace add WadeWarren/gws-claude-plugin
    claude plugins install gws@gws-marketplace

    claude plugins marketplace add uditgoenka/autoresearch
    claude plugins install autoresearch@autoresearch

    claude plugins marketplace add openai/codex-plugin-cc
    claude plugins install codex@openai-codex
fi

if [ "$(uname)"x = "Darwin"x ]; then
    mkdir -p "$HOME/Library/KeyBindings"
    link_file "$CWD/keyboard/DefaultKeyBinding.Dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.Dict"
    link_file "$CWD/spelling/dictionary.txt" "$HOME/Library/Spelling/LocalDictionary"
    mkdir -p "$HOME/Library/Application Support/Code"
    link_dir "$CWD/vscode" "$HOME/Library/Application Support/Code/User"
fi

if [ ! -d vim/bundle/vundle ]; then
    mkdir -p "vim/bundle"
    git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
fi

# Make sure there's a global backup directory for vim.
mkdir -p "vim/backup"

# Install and update Vundle bundles.
if command -v vim >/dev/null 2>&1; then
    vim -c 'VundleInstall' -c 'VundleUpdate' -c 'qa!'
fi

# nvim --headless '+Lazy! sync' +qa

touch "$HOME/.bash_history"
chmod -f 600 "$HOME"/.*_history
chmod -f 600 "$HOME"/.bash_history

# TODO/FIXME:
# rm: $HOME/Library/Application Support/Code/User: Permission denied
# $HOME/Library/Spelling/en
