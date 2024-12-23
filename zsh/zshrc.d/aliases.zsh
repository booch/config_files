#!/bin/zsh

command-exists() {
    type -p "$1" >/dev/null
}

# NOTE: We can add flags to existing aliases like this:
# alias ls="${aliases[ls]:-ls} -A"

# Enable color support of ls and also add handy aliases.
if [ "$TERM" != "dumb" ]; then
    command-exists dircolors && eval "$(dircolors -b)"
    if ls --color=auto 2> /dev/null > /dev/null ; then
        # See http://www.linux-sxs.org/housekeeping/lscolors.html
        export LS_COLORS='di=1:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rb=90'
        alias ls='ls --color=auto -h -1'
    else
        # Mac OS X
        alias ls='ls -G -h -1'
    fi
fi

# Some more `ls` aliases. Use `eza` if it's available.
# TODO: Pipe these to `less -FX` (don't clear screen, exit if one screen).
#       Use this style: https://stackoverflow.com/a/39395740/26311
if command-exists eza ; then
    # TODO: Set EZA_COLORS. See https://man.archlinux.org/man/extra/eza/eza_colors-explanation.5.en
    # Eza has no way to suppress showing the source of soft links, so fall back to `ls`.
    alias l1='ls -1A'
    alias l='eza -lahF --no-user --no-permissions --git --group-directories-first --time-style=relative'
    alias ll='eza -lahFo --git --group-directories-first --time-style=long-iso'
    alias ltr='eza -lahF --no-user --no-permissions --group-directories-first --git --sort=time --time-style=relative'
    alias dir='eza -1'
else
    alias l1='ls -1A'
    alias l='ls -lAFGh'
    alias ll='ls -lAFGh'
    alias ltr='ls -ltrAFGh'
    alias dir='ls -1'
fi

# Completion colors should match $LS_COLORS.
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"


alias cd='pushd'
alias pop='popd'
alias home='pushd ~'
# alias ..='cd ..'

alias du='du -kh'   # See du replacement below.
if df -T >/dev/null 2>/dev/null; then
    alias df='df -kTh'
else
    alias df='df -kh'
fi

alias lstrings='strings $1 | less'

alias tree='tree -Csu'		# nice alternative to 'ls'

# If we've got vim (which we hopefully do!), alias vi as vim.
which vim > /dev/null && alias vi=vim

# If we call Emacs from the command line, don't open it in a GUI window.
alias emacs='emacs -nw'

# Typos
alias more='less'
alias kess='less'
alias ks='ls'
alias xs='cd'

# If we aren't on MacOS, create an `open` alias.
if [[ $(uname -a) =~ 'Linux' ]]; then
    alias open='xdg-open'
fi

# Other Mac OS X stuff.
if [ -x '/Applications/Firefox.app/Contents/MacOS/firefox' ]; then
    alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
fi
if [ -x '/Applications/VLC.app/Contents/MacOS/VLC' ]; then
    alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
fi
if where hdiutil >/dev/null; then
    alias eject='hdiutil eject'
fi
if [ -x '/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession' ]; then
    alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
fi


# Show top 10 most frequent items in the list piped in. Can specify top 20 with 'top10 -20'.
alias top10='sort | uniq -c | sort -nr | head'


# From RailsTips.org:
# Use: cdgem <gem name>, cd's into your gems directory and opens gem that best matches the gem name provided.
cdgem() {
    cd "$GEM_HOME/gems/" || exit
    # shellcheck disable=SC2164 disable=SC2010
    cd "$(ls | grep "$1" | sort | tail -1)"
}


# If htop is installed, use it instead of top.
if which htop >/dev/null; then
    alias top=htop
fi

# Make du print in human readable form, and sorted by size (largest last). From http://www.earthinfo.org/linux-disk-usage-sorted-by-size-and-human-readable/.
_du() {
    \du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ "$size" -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size="$(echo "scale=1; $size / 1024" | bc)"; done; done
}
alias du=_du

# Unless we already have a json formatter, add a simple one.
if ! which json >/dev/null; then
    alias json='python -mjson.tool'
fi

# Emulate Mac OS X paste buffer on Linux.
if [ ! "$(uname -s)" = 'Darwin' ]; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
fi

# Make Ripgrep (rg) output pretty, and pipe it to `less`, unless output is being piped elsewhere.
_rg() {
    if [[ -t 1 ]]; then
        command rg --pretty "$@" | less -RX
    else
        command rg --pretty "$@"
    fi
}
alias rg=_rg

# The kubernetes Oh My ZSH plugin adds `k` and a ton of other aliases, but the rest aren't used much.
alias k='kubectl'

# Aliases (shell functions) for zoxide.
if command -v zoxide >& /dev/null; then
    # Adds `z` and `zi` (interactive).
    eval "$(zoxide init zsh)"
    alias cd='z'
fi
