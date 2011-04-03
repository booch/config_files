# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, exit this file.
[ -z "$PS1" ] && return

# I like to have sbin directories in my path.
export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin

# Add personal bin directory, if it exists.
if [ -d $HOME/bin ]; then
    export PATH=$HOME/bin:$PATH
fi


# Don't put duplicate lines in the history. Don't record lines starting with a space. See bash(1) for more options.
# (NOTE: Be sure not to overwrite GNU Midnight Commander's setting of `ignorespace'.)
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups,ignorespace

# Append to the history file, don't overwrite it.
shopt -s histappend

# Save commands immediately, to solve the multiple window problem (see http://www.ukuug.org/events/linux2003/papers/bash_tips/#S4).
export PROMPT_COMMAND='history -a'

# Save timestamps in the history file.
export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S '

# Don't add these commands to the shell history. (& = duplicate lines)
export HISTIGNORE="&:exit"


# When doing a 'cd', look in these directories for the destination.
# I didn't like this, as it messes up completion too.
#export CDPATH=.:~:~/work:/home/web:/usr/local:/usr/lib:/usr/share:/usr/src:/

# Ignore words ending with these suffixes, when doing tab completion.
export FIGNORE='~:.o:.svn:vmlinuz'


# Bash completion settings (actually, these are readline settings)
bind "set completion-ignore-case on" # note: bind is used instead of setting these in .inputrc.  This ignores case in bash completion
bind "set bell-style none" # No bell, because it's damn annoying
bind "set show-all-if-ambiguous On" # this allows you to automatically show completion without double tab-ing

# Make sure we're using Emacs-style command-line editing, not vi-style.
set -o emacs

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
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


# Set the default editor to nano, if it exists. Next best choice is pico, then vim.
if type -P nano >/dev/null; then
    export EDITOR=nano
    alias pico=nano
elif type -P pico >/dev/null; then
    export EDITOR=pico
    alias nano=pico
elif type -P vim >dev/null; then
    export EDITOR=vim
    alias nano=vim
    alias pico=vim
fi


ulimit -S -c 0        # Don't want any coredumps
set -o notify		# ???
shopt -u mailwarn
unset MAILCHECK       # I don't want my shell to warn me of incoming mail


export PAGER=less
export LESSCHARSET='latin1'


# Highlight matching strings if grep command is run interactively.
export GREP_OPTIONS='--color=auto'


# Set variable identifying the chroot you work in (used in the prompt below).
if [ -z "$chroot" ] && [ -r /etc/debian_chroot ]; then
    chroot=$(cat /etc/debian_chroot)
fi


# From http://blog.infinitered.com/entries/show/4
export COLOR_NONE='\e[0m'
export COLOR_WHITE='\e[1;37m'
export COLOR_BLACK='\e[0;30m'
export COLOR_BLUE='\e[0;34m'
export COLOR_LIGHT_BLUE='\e[1;34m'
export COLOR_GREEN='\e[0;32m'
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_CYAN='\e[0;36m'
export COLOR_LIGHT_CYAN='\e[1;36m'
export COLOR_RED='\e[0;31m'
export COLOR_LIGHT_RED='\e[1;31m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_LIGHT_PURPLE='\e[1;35m'
export COLOR_BROWN='\e[0;33m'
export COLOR_YELLOW='\e[1;33m'
export COLOR_GRAY='\e[0;30m'
export COLOR_LIGHT_GRAY='\e[0;37m'
alias colorslist="set | egrep 'COLOR_\w*'"  # lists all the colors


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
PS1='${chroot:+($chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[0;33m\]$(parse_git_branch)\[\033[00m\]\$ '

# Change color to red for root, to make it stand out more.
if [ "`id -u`" -eq 0 ]; then
    PS1='${chroot:+($chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}: ${PWD/$HOME/~}\007"'
    ;;
*)
    ;;
esac

# Or set the window title to the current directory.
#function settitle() { echo -ne "\e]2;$@\a\e]1;$@\a"; }
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
elif [ -r /usr/local/bin/bash_completion ]; then
    export BASH_COMPLETION=/usr/local/bin/bash_completion
    export BASH_COMPLETION_DIR=~/bin/bash_completion.d
    . /usr/local/bin/bash_completion
elif [ -r ~/bin/bash_completion ]; then
    export BASH_COMPLETION=~/bin/bash_completion
    export BASH_COMPLETION_DIR=~/bin/bash_completion.d
    . ~/bin/bash_completion
fi


# Allow pulling in some private settings.
if [ -f ~/.bashrc-private ]; then
    . ~/.bashrc-private
fi
