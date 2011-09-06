# NOTE: This .bash_profile is executed only for bash login shells.

# By default, do not let others on the system write files I create, but let them read.
umask 022

# Include .bashrc if it exists, because all login shells are interactive.
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# If I have a ~/bin directory, add it to my $PATH, ahead of everything else. TODO: Should be in .bashrc, I think.
if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

# Output some info about the system.
if lsb_release 2>/dev/null; then
    OS="$(lsb_release -d | sed -e 's/^Description:\s*//')"
else
    OS="$(uname -sr)"
fi
echo -e "${COLOR_BLUE}Server time: $(date +'%Y-%m-%d') $(uptime)${COLOR_NONE}"
echo -e "${COLOR_PURPLE}${OS}${COLOR_NONE} - ${COLOR_BROWN}bash ${BASH_VERSION}${COLOR_NONE}"
