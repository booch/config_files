# Enable command completion for everything in Homebrew.
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

# Make tab completion case insensitive. (From https://scriptingosx.com/2019/07/moving-to-zsh-part-5-completions/.)
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Allow tab completion of multiple partial matches (/u/lo/b -> /usr/local/bin).
zstyle ':completion:*' list-suffixeszstyle ':completion:*' expand prefix suffix

# Enable tab completion.
autoload -Uz compinit && compinit

# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS='true'

# Enable automatic suggestions (a la Fish), selected with right arrow.
# TODO: Configure zsh-autosuggestions. See https://github.com/zsh-users/zsh-autosuggestions.
if [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
