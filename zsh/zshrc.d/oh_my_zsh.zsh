# Make sure Oh My Zsh knows where to find all its stuff.
export ZSH='/usr/local/share/oh-my-zsh'
export ZSH_CUSTOM="$HOME/.zsh/custom"

# Oh My Zsh plugins.
# TODO: I can/should replace all these (including the theme) with simple scripts in ~/.shh/szhrc.d/.
# TODO: Look into adding:
#   colored-man-pages
#   ssh-agent, gpg-agent
#   tmuxinator (seems to only have completions)
#   tmux (set ZSH_TMUX_FIXTERM=false)
#   z (or some other autojump, like fasd, autojump, v))
#   github
#   https://github.com/igoradamenko/jira.plugin.zsh
#   https://github.com/wulfgarpro/history-sync
#   https://gist.github.com/oshybystyi/475ee7768efc03727f21
#   mix
#   npm
#   bundler (eliminates need to do `bundle exec`)
#   brew - adds nothing useful, except alias brews='brew list -1`
#   asdf (loads for you) or chruby
#   aws
#   common-aliases
#   compleat
#   git (really only want current_branch and current_repository)
#   httpie
#   kubectl (really only want alias k=kubectl and completion)
#   yarn (auto-complete)
#   per-directory-history
#   emacs
#   ripgrep (completions)
plugins=(asdf bundler common-aliases)

# Use a nice prompt.
ZSH_THEME='powerlevel10k/powerlevel10k'

# Start up Oh My Zsh.
source $ZSH/oh-my-zsh.sh
