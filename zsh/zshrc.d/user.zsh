# Set some user-specific environment variables for ease of use.

# LOL. Copilot suggested 'Booch McBoochface' as the full name.
if [[ "$USER" == 'booch' || "$USER" == 'craigbuchek' ]]; then
    export USER_FULL_NAME='Craig Buchek'
    export USER_EMAIL_ADDRESS='craig@boochtek.com'
else
    echo 'WARNING: Unknown user. Please update `zshrc.d/user.zsh`.'
fi
