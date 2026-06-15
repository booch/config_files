#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# NOTE: We can add flags to existing aliases like this:
# alias ls="${aliases[ls]:-ls} -A"

# Aliases for preparing to work on a project.
# These will make it easier for me to close windows.

alias resume='cd ~/Work/resume'
alias stone='cd ~/Work/stone'
alias configs='cd ~/.configs'
alias job-hunt='echo "open VS Code workspace, open tmux windows?"'
alias cleanup='brew cleanup;'
alias update="brew update 2>&1 | awk '{\$1=\$1};1' | tr ' \t\n' '\n' >> ~/mac_setup/homebrew-new-packages.md ; brew upgrade; brew dr"
alias stats='check_alias_usage' # Part of zsh-you-should-use
alias backup='echo "TODO: implement backup functionality"'
alias sync='echo "TODO: synchronize configuration files across devices"'
alias work='echo "TODO: open tmux windows, open VS Code workspace, open Obsidian page"'
