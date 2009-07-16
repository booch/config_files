# Enable color support of ls and also add handy aliases
if [ "$TERM" != "dumb" ]; then
    if type -P dircolors >/dev/null; then
        eval "`dircolors -b`"
    fi
    if ls --color=auto 2> /dev/null > /dev/null ; then
        alias ls='ls --color=auto -h'
        alias dir='ls --color=auto --format=vertical'
    else
        # Mac OS X
        alias ls='ls -G -h'
        alias dir='ls -G'
    fi
fi

# Some more ls aliases
alias ll='ls -lAFGh'
alias l='ls -lAFGh'
alias ltr='ls -ltrAFGh'

alias cd='pushd'
alias pop='popd'
alias home='pushd ~'
alias ..='cd ..'

alias du='du -kh'   # See du replacement below.
alias df='df -kTh'

alias lstrings='strings $1 | less'

alias tree='tree -Csu'		# nice alternative to 'ls'

# If we've got vim (which we hopefully do!), alias vi as vim.
which vim > /dev/null && alias vi=vim

alias more='less'
alias kess='less'
alias ks='ls'
alias xs='cd'


# Other Mac OS X stuff.
if [ -x '/Applications/Komodo Edit.app/Contents/MacOS/komodo' ]; then
  alias komodo='/Applications/Komodo\ Edit.app/Contents/MacOS/komodo'
fi
if [ -x '/Applications/Firefox.app/Contents/MacOS/firefox' ]; then
  alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
fi
if [ -x '/Applications/TextMate.app/Contents/SharedSupport/Support/bin/mate' ]; then
  alias mate='/Applications/TextMate.app/Contents/SharedSupport/Support/bin/mate'
fi
if [ -x '/Applications/VLC.app/Contents/MacOS/VLC' ]; then
  alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
fi


# Show top 10 most frequent items in the list piped in. Can specify top 20 with 'top10 -20'.
alias top10='sort | uniq -c | sort -nr | head'


# From RailsTips.org:
# Use: cdgem <gem name>, cd's into your gems directory and opens gem that best matches the gem name provided.
function cdgem {
  cd $GEM_HOME/gems/; cd `ls|grep $1|sort|tail -1`
}


# If htop is installed, use it instead of top.
if type -P htop >/dev/null; then
  alias top=htop
fi

# Make du print in human readable form, and sorted by size (largest last). From http://www.earthinfo.org/linux-disk-usage-sorted-by-size-and-human-readable/.
function _du {
  \du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ $size -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size=`echo "scale=1; $size / 1024" | bc`; done; done
}
alias du=_du
