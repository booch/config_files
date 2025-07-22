# Set some user-specific environment variables for ease of use.


local THIS_FILE="${(%):-%N}"


if [[ "$(uname)" == "Darwin" ]]; then
    export USER_FULL_NAME="$(id -F)"
else
    export USER_FULL_NAME="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"
fi


if [[ "$HOST" == 'Buchek-FNWWVWCRWN' ]]; then
    export USER_EMAIL_ADDRESS="$USER@paynearme.com"
elif [[ "$USER" == 'booch' || "$USER" == 'craigbuchek' ]]; then
    export USER_EMAIL_ADDRESS='craig@boochtek.com'
else
    echo "WARNING: Unknown user. Please set USER_EMAIL_ADDRESS in '$THIS_FILE'."
fi
