# Set some user-specific environment variables for ease of use.
# This file gets sourced by both Bash and Zsh startup scripts.

# Path to this file, for the warning message below. The prompt-expansion form
# is zsh-only, so guard it; bash never evaluates that branch.
if [ -n "$BASH_VERSION" ]; then
    THIS_FILE="${BASH_SOURCE[0]}"
else
    THIS_FILE="${(%):-%N}"
fi

if [[ "$(uname)" == "Darwin" ]]; then
    export USER_FULL_NAME="$(id -F)"
else
    export USER_FULL_NAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"
fi

# zsh sets $HOST; bash sets $HOSTNAME. Use whichever is available.
HOSTNAME="${HOST:-$HOSTNAME}"

if [[ "$HOSTNAME" == 'Buchek-FNWWVWCRWN' ]]; then
    export USER_EMAIL_ADDRESS="$USER@paynearme.com"
elif [[ "$USER" == 'booch' || "$USER" == 'craigbuchek' ]]; then
    export USER_EMAIL_ADDRESS='craig@boochtek.com'
elif [[ "$HOSTNAME" == 'moti' ]]; then
    export USER_EMAIL_ADDRESS='N/A'
else
    echo "WARNING: Unknown user. Please set USER_EMAIL_ADDRESS in '$THIS_FILE'."
fi
