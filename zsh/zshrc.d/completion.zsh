# Enable command completion for everything in Homebrew.
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

autoload -Uz compinit
compinit

# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS='true'
