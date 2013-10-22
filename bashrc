# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, exit this file.
[ -z "$PS1" ] && return

# Make sure locally installed binaries come before system binaries.
export PATH=/usr/local/bin:$PATH

# I like to have sbin directories in my path.
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

# Add personal bin directory, if it exists.
if [ -d $HOME/bin ]; then
    export PATH=$HOME/bin:$PATH
fi


# Don't put duplicate lines in the history. Don't record lines starting with a space. See bash(1) for more options.
# (NOTE: Be sure not to overwrite GNU Midnight Commander's setting of `ignorespace'.)
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups,ignorespace

# Append to the history file, don't overwrite it.
shopt -s histappend

# Save commands immediately, to solve the multiple window problem (see http://www.ukuug.org/events/linux2003/papers/bash_tips/#S4). Add 'history -n' to reload the history file.
export PROMPT_COMMAND="${PROMPT_COMMAND:-:} history -a ;"

# Save timestamps in the history file.
export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S '

# Don't add these commands to the shell history. (& = duplicate lines)
export HISTIGNORE="&:exit:logout:history:bg:fg:jobs"

# Increase history to keep 10000 lines in memory ($HISTSIZE), and in the .bash_history file ($HISTFILESIZE).
# NOTE: The history-size option in your .inputrc controls searching through your history. Make sure it's set to 0 (unlimited, the default) or something reasonable.
export HISTSIZE=10000
export HISTFILESIZE=10000

# Save all lines of a multiple-line command in the same history entry, to allow easy editing.
shopt -s cmdhist


# When doing a 'cd', look in these directories for the destination.
# I didn't like this, as it messes up completion too.
#export CDPATH=.:~:~/work:/home/web:/usr/local:/usr/lib:/usr/share:/usr/src:/

# Ignore words ending with these suffixes, when doing tab completion.
export FIGNORE='~:.o:.svn:vmlinuz'


# Bash completion settings (actually, these are readline settings)
bind "set completion-ignore-case on"      # Note: bind is used instead of setting these in .inputrc.  This makes bash completion case insensitive.
bind "set bell-style none"                # No bell, because it's annoying.
bind "set show-all-if-ambiguous On"       # Show ambiguous completions without having to hit tab a second time.

# Make sure we're using Emacs-style command-line editing, not vi-style.
set -o emacs

# Report status of terminated background jobs immediately, instead of waiting for next prompt.
set -o notify

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Correct minor spelling errors in 'cd' commands.
shopt -s cdspell

# Expand to complete an ignored word, if no other words match.
shopt -u force_fignore

# Don't try to find all the command possibilities when hitting TAB on an empty line.
shopt -s no_empty_cmd_completion

# Exit the shell if we get 3 CTRL-D in a row.
export IGNOREEOF=3


# When running less, always ignore case on searches; prompt verbosely; display colors;
#  chop long lines; highlight first new line; tabs are 4 chars wide.
export LESS='-I -M -R -S -W -x4'

# Make less more friendly for non-text input files. See lesspipe(1).
if type -P lesspipe >/dev/null; then
    export LESSPIPE=lesspipe
elif type -P lesspipe.sh >/dev/null; then
    export LESSPIPE=lesspipe.sh
fi
[ -n "$LESSPIPE" ] && eval "$(SHELL=/bin/sh $LESSPIPE)"



# Set the default editor to nano, if it exists. Next best choice is pico, then vim.
if type -P nano >/dev/null; then
    export EDITOR=nano
    alias pico=nano
elif type -P pico >/dev/null; then
    export EDITOR=pico
    alias nano=pico
elif type -P vim >/dev/null; then
    export EDITOR=vim
    alias nano=vim
    alias pico=vim
fi


# Don't produce core dumps.
ulimit -S -c 0


# Don't bother telling us if we have unread or read emails.
shopt -u mailwarn
unset MAILCHECK


# Use less (instead of more) anywhere paging is required.
export PAGER=less


# We should be able to use UTF-8 everywhere these days.
export LESSCHARSET='utf-8'


# Highlight matching strings if grep command is run interactively. Highlight in green, instead of the default red.
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'


# Set variable identifying the chroot you work in (used in the prompt below).
if [ -z "$chroot" ] && [ -r /etc/debian_chroot ]; then
    chroot=$(cat /etc/debian_chroot)
fi


# From http://blog.infinitered.com/entries/show/4
export COLOR_NONE='\033[0m'
export COLOR_WHITE='\033[1;37m'
export COLOR_BLACK='\033[0;30m'
export COLOR_BLUE='\033[0;34m'
export COLOR_LIGHT_BLUE='\033[1;34m'
export COLOR_GREEN='\033[0;32m'
export COLOR_LIGHT_GREEN='\033[1;32m'
export COLOR_CYAN='\033[0;36m'
export COLOR_LIGHT_CYAN='\033[1;36m'
export COLOR_RED='\033[0;31m'
export COLOR_LIGHT_RED='\033[1;31m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_LIGHT_PURPLE='\033[1;35m'
export COLOR_BROWN='\033[0;33m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_GRAY='\033[0;30m'
export COLOR_LIGHT_GRAY='\033[0;37m'
alias colorslist="set | egrep 'COLOR_\w*'"  # Lists all the colors.


# Set prompt with info on current git branch, if any (from http://railstips.org/2009/2/2/bedazzle-your-bash-prompt-with-git-info, http://asemanfar.com/Current-Git-Branch-in-Bash-Prompt).
function parse_git_branch {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo "("${ref#refs/heads/}")"
}
# Other possible ways to determine current git branch.
#function parse_git_branch {
#  git branch &>/dev/null
#  if [ $? -eq 0 ]; then
#    echo " ($(git branch | grep ^*|sed s/\*\ //))"
#  fi
#}
#function parse_git_branch() {
#  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
#}
#function parse_git_branch() {
#  git name-rev HEAD 2> /dev/null | awk "{ print \\$2 }"
#}
PS1='${chroot:+($chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[0;33m\]$(parse_git_branch)\[\033[00m\]\n\$ '

# Change color to red for root, to make it stand out more.
if [ "`id -u`" -eq 0 ]; then
    PS1='${chroot:+($chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n\[\033[01;31m\]\$\[\033[00m\] '
fi


## Handle PuTTY oddities.

# Get the first 5 characters of the terminal answerback string. (PuTTY's default answerback string is "PuTTY", without a terminating return character.)
echo -ne '\005' ; read -s -t1 -n5 TERMINAL_ANSWERBACK_5

# See if we got the PuTTY answerback.
if [[ "$TERMINAL_ANSWERBACK_5" == 'PuTTY' ]]; then
    # Use a PuTTY-specific terminal type if we can.
    if [[ -f '/usr/share/terminfo/p/putty-256color' ]]; then
        export TERM='putty-256color'
    elif [[ -f '/usr/share/terminfo/p/putty' ]]; then
        export TERM='putty'
    else
        export TERM='xterm'
    fi

    # Enable UTF-8 in PuTTY (from http://www.earth.li/~huggie/blog/tech/mobile/putty-utf-8-trick.html).
    # The \e%G sets UTF-8 mode; \e[?47h and \e[?47l switch to the alternative screen and back.
    echo -ne '\e%G\e[?47h\e%G\e[?47l'
fi


# If the terminal supports xterm-style setting of the title, set it to user@host:dir after every command.
case "$TERM" in
xterm*|rxvt*|putty*)
    PROMPT_COMMAND="${PROMPT_COMMAND:-:} echo -ne \"\\033]0;${USER}@${HOSTNAME%%.*}: \${PWD/\$HOME/~}\\007\" ;"
    ;;
*)
    ;;
esac

# Or set the window title to the current directory.
#function settitle() { echo -ne "\033]2;$@\a\033]1;$@\a"; }
#function cd() { command cd "$@"; settitle `pwd -P`; }


# Allow for non-Bash Bourne shell:
#if [ "$BASH" ]; then
#  PS1='\u@\h:\w\$ '
#else
#  if [ "`id -u`" -eq 0 ]; then
#    PS1='# '
#  else
#    PS1='$ '
#  fi
#fi


# Pull in shell alias definitions.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi


# Enable programmable completion features.
if [ -r /etc/bash_completion -a ! -z "$BASH_COMPLETION" ]; then
    . /etc/bash_completion
elif [ -r /usr/local/etc/bash_completion ]; then
    . /usr/local/etc/bash_completion # Homebrew for Mac installs here.
elif [ -r /usr/local/bin/bash_completion ]; then
    export BASH_COMPLETION=/usr/local/bin/bash_completion
    export BASH_COMPLETION_DIR=~/bin/bash_completion.d
    . /usr/local/bin/bash_completion
elif [ -r ~/bin/bash_completion ]; then
    export BASH_COMPLETION=~/bin/bash_completion
    export BASH_COMPLETION_DIR=~/bin/bash_completion.d
    . ~/bin/bash_completion
fi

# If we stop console output with Ctrl+S, allow any key to restart the output.
stty ixany

# Allow pulling in some private settings.
if [ -f ~/.bashrc-private ]; then
    . ~/.bashrc-private
fi

# RVM (Ruby Version Manager)
if [[ -s "$HOME/.rvm/scripts/rvm" ]]  ; then source "$HOME/.rvm/scripts/rvm" ; fi

# rbenv Ruby environment manager
if which rbenv >/dev/null ; then eval "$(rbenv init -)" ; fi

## Mac OS X specific settings.
if [[ "$OSTYPE" = "darwin10.0" ]] ; then
    if [[ "$HOSTTYPE" = "x86_64" ]] ; then
        export ARCHFLAGS="-arch x86_64" # Ensure that mysql gem builds correctly.
    fi
fi


## Android SDK.
export ANDROID_SDK_VERSION='21.0.1'
if [[ -d /Applications/Android/SDK/$ANDROID_SDK_VERSION ]] ; then
    PATH=$PATH:/Applications/Android/SDK/$ANDROID_SDK_VERSION/tools:/Applications/Android/SDK/$ANDROID_SDK_VERSION/platform-tools
fi

# Make sure binaries from Node (npm) packages are in our path.
export PATH="$PATH:/usr/local/share/npm/bin"
