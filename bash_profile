# NOTE: This .bash_profile is executed only for bash login shells.

# By default, do not let others on the system write files I create, but let them read.
umask 022

# Include .bashrc if it exists, because all login shells are interactive.
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Output some info about the system.
if lsb_release 2>/dev/null; then
    OS="$(lsb_release -d | sed -e 's/^Description:\s*//')"
else
    OS="$(uname -sr)"
fi
echo -e "${COLOR_BLUE}Server time: $(date +'%Y-%m-%d') $(uptime)${COLOR_NONE}"
echo -e "${COLOR_PURPLE}${OS}${COLOR_NONE} - ${COLOR_BROWN}bash ${BASH_VERSION}${COLOR_NONE}"

# Pull in settings from other (possibly system-specific or private) files.
if [[ -d $HOME/.profile.d ]]; then
    for profile_file in $(find -L $HOME/.profile.d/ -type f); do
        source $profile_file
    done
fi
