# Change datestamp format for `history` output.
HIST_STAMPS='yyyy-mm-dd'

# Keep my home directory clean.
HISTFILE=$HOME/.zsh/history

# Allow for a really large history file.
HISTSIZE=20000
SAVEHIST=10000

# From https://gitlab.com/sytses/dotfiles/-/blob/master/zsh/config.zsh
setopt HIST_VERIFY
setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
