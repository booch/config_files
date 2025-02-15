
SSH_ID_FILE="${HOME}/.ssh/id_ed25519"
PID_FILE="${XDG_STATE_HOME:-$HOME/.ssh}/ssh-agent.pid"

# Remove the PID file if it's no longer valid.
if [[ -f "${PID_FILE}" ]] && ! pgrep -x ssh-agent -F "${PID_FILE}" > /dev/null; then
    rm -f "${PID_FILE}"
fi

# Start ssh-agent if it's not already running; otherwise get the PID from the PID file.
if ! [[ -f "${PID_FILE}" ]]; then
    eval "$(ssh-agent -s)"
    echo "${SSH_AGENT_PID}" > "${PID_FILE}"
    chmod 600 "${PID_FILE}"
else
    export SSH_AGENT_PID="$(cat "${PID_FILE}" 2> /dev/null)"
fi

# Add SSH key to agent. This is idempotent.
if [[ "$(uname)" == 'Darwin' ]]; then
    # Use Keychain to retrieve passphrase.
    ssh-add --apple-load-keychain "${SSH_ID_FILE}" > /dev/null 2>&1
else
    ssh-add "${SSH_ID_FILE}" > /dev/null 2>&1
fi
