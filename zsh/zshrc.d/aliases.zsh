#!/bin/bash
#!/bin/zsh
# This should be able to run in both Bash and Zsh.

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
    alias ll='eza -lahoF --git --group-directories-first --time-style=long-iso'
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
if [[ -n "$ZSH_VERSION" ]] ; then
    zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
fi

alias cd='pushd'
alias pop='popd'
alias home='pushd ~'

alias lstrings='strings $1 | less'

# Tree is a nice alternative to `ls -R`.
alias tree='tree -C --gitignore'

# If we've got vim (which we hopefully do!), alias vi as vim.
command-exists vim && alias vi=vim

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
if command-exists htop ; then
    alias top=htop
fi

# Make du print in human readable form, and sorted by size (largest last). From http://www.earthinfo.org/linux-disk-usage-sorted-by-size-and-human-readable/.
_du() {
    : # command du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ "$size" -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size="$(echo "scale=1; $size / 1024" | bc)"; done; done
    command du -sk "$@" | sort -n
}
alias du=_du

# Unless we already have a JSON formatter, add a simple one.
if ! command-exists json ; then
    alias json='python -m json.tool'
fi

# Emulate Mac OS X paste buffer on Linux.
if [ ! "$(uname -s)" = 'Darwin' ]; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
fi

# Pipe ripgrep (rg) output to `delta`, unless output is being piped elsewhere.
# BUG: delta (as of 0.18.2) is not printing the stats, and has no way to change separators.
# NOTE: delta (as of 0.18.2) grep output is way behind git output as far as nice formatting.
#       For example, line numbers don't look nice, file names aren't nicely formatted, etc.
_rg() {
    if [[ -t 1 ]]; then
        command rg "$@" | less
    else
        command rg "$@"
    fi
}
alias rg=_rg

# The kubernetes Oh My ZSH plugin adds `k` and a ton of other aliases, but the rest aren't used much.
alias k='kubectl'

# Aliases (shell functions) for zoxide.
if command-exists zoxide ; then
    # Adds `z` and `zi` (interactive).
    eval "$(zoxide init "$(basename "$SHELL")")"
    alias cd='z'
fi

# Alias `dog` as `dig`, if it's available, or `doggo` if it's available.
if command-exists dog ; then
    alias dig=dog
elif command-exists doggo ; then
    alias dig=doggo
fi

# Aliases for voice control.
alias Get='git'
