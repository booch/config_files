#!/bin/bash

# Make certain we're in the directory containing this file.
cd "$(dirname "${BASH_SOURCE[0]:-$0}")" || (echo "$(tput setaf 1)Could not change to script directory$(tput sgr0)" && exit)

# Get full path to the directory.
CWD="$(pwd)"

TODAY="$(date +%Y%m%d)"

# Move an existing path aside without overwriting an earlier backup.
backup_path() {
    local path="$1"
    local backup="${path}-${TODAY}"
    local count=1

    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="${path}-${TODAY}-${count}"
        count=$((count + 1))
    done

    mv "$path" "$backup"
}

# Symlink a file, backing up any existing regular file.
# Existing symlinks are replaced silently (idempotent).
link_file() {
    src="$1"
    dst="$2"
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        backup_path "$dst"
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
            copy_missing_dir_contents "$home_dir" "$config_dir"
        fi
    fi
    link_dir "$config_dir" "$home_dir"
}

copy_missing_dir_contents() {
    local src="$1"
    local dst="$2"

    if command -v rsync >/dev/null; then
        rsync -a --ignore-existing "$src"/ "$dst"/
    else
        cp -an "$src"/. "$dst"/
    fi
}

link_xdg_path() {
    local config_path="$1"
    local xdg_path="$2"
    local kind="$3"
    local old_target=""

    mkdir -p "$(dirname "$config_path")" "$(dirname "$xdg_path")"

    if [ "$kind" = "dir" ]; then
        mkdir -p "$xdg_path"
    fi

    if [ -L "$config_path" ]; then
        old_target="$(readlink "$config_path")"
        if [ "$old_target" = "$xdg_path" ]; then
            return
        fi
        if [ "$kind" = "dir" ] && [ -d "$config_path" ]; then
            copy_missing_dir_contents "$config_path" "$xdg_path"
        fi
        rm "$config_path"
    elif [ -e "$config_path" ]; then
        if [ "$kind" = "dir" ] && [ -d "$config_path" ]; then
            copy_missing_dir_contents "$config_path" "$xdg_path"
            backup_path "$config_path"
        elif [ "$kind" = "file" ] && [ -f "$config_path" ]; then
            if [ ! -e "$xdg_path" ]; then
                mv "$config_path" "$xdg_path"
            elif cmp -s "$config_path" "$xdg_path"; then
                rm "$config_path"
            else
                backup_path "$config_path"
            fi
        else
            backup_path "$config_path"
        fi
    fi

    ln -s "$xdg_path" "$config_path"
}

link_xdg_dir() {
    link_xdg_path "$1" "$2" dir
}

link_xdg_file() {
    link_xdg_path "$1" "$2" file
}

link_shared_dir() {
    local link_path="$1"
    local target_path="$2"
    local link_target="$3"

    mkdir -p "$(dirname "$link_path")" "$target_path"

    if [ -L "$link_path" ]; then
        if [ "$(readlink "$link_path")" = "$link_target" ]; then
            return
        fi
        if [ -d "$link_path" ]; then
            copy_missing_dir_contents "$link_path" "$target_path"
        fi
        rm "$link_path"
    elif [ -e "$link_path" ]; then
        if [ -d "$link_path" ]; then
            copy_missing_dir_contents "$link_path" "$target_path"
        fi
        backup_path "$link_path"
    fi

    ln -s "$link_target" "$link_path"
}

setup_codex_xdg_links() {
    local codex_config="$CWD/codex"
    local codex_cache="$XDG_CACHE_HOME/codex"
    local codex_state="$XDG_STATE_HOME/codex"
    local codex_data="$XDG_DATA_HOME/codex"

    mkdir -p "$codex_config" "$codex_cache" "$codex_state" "$codex_data"

    link_xdg_dir "$codex_config/.tmp" "$codex_cache/.tmp"
    link_xdg_dir "$codex_config/cache" "$codex_cache/cache"
    link_xdg_dir "$codex_config/tmp" "$codex_cache/tmp"
    link_xdg_dir "$codex_config/vendor_imports" "$codex_cache/vendor_imports"
    link_xdg_file "$codex_config/cloud-requirements-cache.json" "$codex_cache/cloud-requirements-cache.json"
    link_xdg_file "$codex_config/models_cache.json" "$codex_cache/models_cache.json"

    link_xdg_dir "$codex_config/plugins" "$codex_data/plugins"
    link_xdg_dir "$codex_data/plugins/cache" "$codex_cache/plugins/cache"
    link_shared_dir "$codex_config/skills" "$CWD/ai/skills" "../ai/skills"

    link_xdg_file "$codex_config/.codex-global-state.json" "$codex_state/.codex-global-state.json"
    link_xdg_file "$codex_config/.codex-global-state.json.bak" "$codex_state/.codex-global-state.json.bak"
    link_xdg_file "$codex_config/.personality_migration" "$codex_state/.personality_migration"
    link_xdg_dir "$codex_config/ambient-suggestions" "$codex_state/ambient-suggestions"
    link_xdg_file "$codex_config/auth.json" "$codex_state/auth.json"
    link_xdg_file "$codex_config/goals_1.sqlite" "$codex_state/goals_1.sqlite"
    link_xdg_file "$codex_config/history.jsonl" "$codex_state/history.jsonl"
    link_xdg_file "$codex_config/installation_id" "$codex_state/installation_id"
    link_xdg_dir "$codex_config/log" "$codex_state/log"
    link_xdg_file "$codex_config/logs_2.sqlite" "$codex_state/logs_2.sqlite"
    link_xdg_file "$codex_config/logs_2.sqlite-shm" "$codex_state/logs_2.sqlite-shm"
    link_xdg_file "$codex_config/logs_2.sqlite-wal" "$codex_state/logs_2.sqlite-wal"
    link_xdg_dir "$codex_config/memories" "$codex_state/memories"
    link_xdg_dir "$codex_config/sessions" "$codex_state/sessions"
    link_xdg_dir "$codex_config/shell_snapshots" "$codex_state/shell_snapshots"
    link_xdg_dir "$codex_config/sqlite" "$codex_state/sqlite"
    link_xdg_file "$codex_config/state_5.sqlite" "$codex_state/state_5.sqlite"
    link_xdg_file "$codex_config/state_5.sqlite-shm" "$codex_state/state_5.sqlite-shm"
    link_xdg_file "$codex_config/state_5.sqlite-wal" "$codex_state/state_5.sqlite-wal"
    link_xdg_file "$codex_config/version.json" "$codex_state/version.json"
}

# Create default $XDG_DATA_HOME, $XDG_STATE_HOME, and $XDG_CACHE_HOME.
# See https://specifications.freedesktop.org/basedir-spec/.
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
chmod 700 "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
# TODO: FIXME: $XDG_CACHE_HOME is set to ~/Library/Caches on macOS. Make ~/.cache a symlink to that directory.

# Git identity is personal and not committed (see .gitignore).
# Generate it per-machine on first run, prompting for name/email.
GIT_LOCAL="$CWD/git/local"
if [ ! -f "$GIT_LOCAL" ]; then
    if [ -t 0 ]; then
        echo "Setting up your personal git identity (git/local)..."
        read -r -p "  Full name: " git_name
        read -r -p "  Email address: " git_email
        read -r -p "  GitHub username (optional): " git_github
        {
            printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email"
            [ -n "$git_github" ] && printf '[github]\n\tuser = %s\n' "$git_github"
        } > "$GIT_LOCAL"
        echo "Wrote $GIT_LOCAL"
    else
        echo "No git/local found (non-interactive); create it with your [user] name/email."
    fi
fi

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
setup_codex_xdg_links

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
