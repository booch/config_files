#!/bin/bash

# Make certain we're in the directory containing this file.
cd "$(dirname "$0")" || (echo "$(tput setaf 1)Could not change to script directory$(tput sgr0)" && exit)

# Get full path to the directory.
CWD="$(pwd)"

TODAY="$(date +%Y%m%d)"

# We've added backups of any existing files/directories.
# This should work for regular files and directories.
ln_sf() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ]; then
        if [ ! -e "${dst}-${TODAY}" ]; then
            mv "$dst" "${dst}-${TODAY}"
        else
            rm -rf "$dst"
        fi
    fi
    ln -s "$src" "$dst"
}

# We'd use `ln -sfT` on Linux, if we didn't want the backups.
# According to the macOS man page, `ln -sfF` should work the same, but it does not.
ln_sfT() {
    ln_sf "$1" "$2"
}

# Create default $XDG_DATA_HOME, $XDG_STATE_HOME, and $XDG_CACHE_HOME.
# See https://specifications.freedesktop.org/basedir-spec/.
mkdir -p "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"
chmod 700 "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"

# Link files to where they "belong". Hopefully some day, all commands will support `~/.config` or `$XDG_CONFIG_HOME`.
ln_sf "$CWD/ack/ackrc" "$HOME/.ackrc"

ln_sf "$CWD/zsh/zshrc" "$HOME/.zshrc"
ln_sfT "$CWD/zsh" "$HOME/.zsh"

ln_sf "$CWD/bash/aliases" "$HOME/.bash_aliases"
ln_sf "$CWD/bash/bash_logout" "$HOME/.bash_logout"
ln_sf "$CWD/bash/bash_profile" "$HOME/.bash_profile"
ln_sf "$CWD/bash/bashrc" "$HOME/.bashrc"
ln_sf "$CWD/bash/profile" "$HOME/.profile"
ln_sfT "$CWD/bash/profile.d" "$HOME/.profile.d"
ln_sf "$CWD/bash/inputrc" "$HOME/.inputrc"

ln_sfT "$CWD/ruby/bundler" "$HOME/.bundle"
ln_sf "$CWD/ruby/gemrc" "$HOME/.gemrc"
ln_sf "$CWD/ruby/pryrc" "$HOME/.pryrc"
ln_sf "$CWD/ruby/aprc" "$HOME/.aprc"
ln_sf "$CWD/ruby/railsrc" "$HOME/.railsrc"
ln_sf "$CWD/ruby/ruby-version" "$HOME/.ruby-version"
ln_sf "$CWD/ruby/rubocop.yml" "$HOME/.rubocop.yml"
ln_sf "$CWD/ruby/default-gems" "$HOME/.default-gems"

# NOTE: Global elintrc files are deprecated and give a warning.
# ln_sf "$CWD/js/eslintrc.yml"             "$HOME/.eslintrc.yml"
ln_sf "$CWD/js/jscsrc" "$HOME/.jscsrc"
ln_sf "$CWD/js/jshintrc" "$HOME/.jshintrc"

link_dir "$CWD/usql" "$HOME/Library/Application Support/usql"

ln_sf "$CWD/markdown/markdownlint.yaml" "$HOME/.markdownlint.yaml"
ln_sf "$CWD/markdown/markdownlint-cli2.jsonc" "$HOME/.markdownlint-cli2.jsonc"

ln_sf "$CWD/ctags" "$HOME/.ctags"

ln_sf "$CWD/finicky/finicky.js" "$HOME/.finicky.js"

ln_sfT "$CWD/docker" "$HOME/.docker"

ln_sfT "$CWD/mc" "$HOME/.mc"

ln_sf "$CWD/nano/nanorc" "$HOME/.nanorc"
ln_sfT "$CWD/nano" "$HOME/.nano"

ln_sf "$CWD/less/lessfilter" "$HOME/.local/bin/lessfilter"
ln_sf "$CWD/vim/vimrc" "$HOME/.vimrc"
ln_sfT "$CWD/vim" "$HOME/.vim"

ln_sfT "$CWD/atom" "$HOME/.atom"

ln_sf "$CWD/postgresql/psqlrc" "$HOME/.psqlrc"

ln_sfT "$CWD/claude" "$HOME/.claude"

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
fi

if [ "$(uname)"x = "Darwin"x ]; then
    mkdir -p "$HOME/Library/KeyBindings"
    ln_sf "$CWD/keyboard/DefaultKeyBinding.Dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.Dict"
    ln_sf "$CWD/spelling/dictionary.txt" "$HOME/Library/Spelling/LocalDictionary"
    mkdir -p "$HOME/Library/Application Support/Code"
    ln_sfT "$CWD/vscode" "$HOME/Library/Application Support/Code/User"
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
