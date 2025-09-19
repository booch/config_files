#!/bin/bash
#!/bin/zsh
# This should be able to run in both Bash and Zsh.


PID_FILE="${XDG_STATE_HOME:-$HOME/.ssh}/ssh-agent.pid"


# Exit if we don't have ssh-agent binary available.
if ! command -v ssh-agent > /dev/null; then
    return 0
fi

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

# Add SSH keys to agent. This is idempotent.
if find "$HOME/.ssh" -maxdepth 1 -name '*.pub' -print -quit | grep -q .; then
    for PUBLIC_KEY in $(echo $HOME/.ssh/*.pub); do
        PRIVATE_KEY="${PUBLIC_KEY%.pub}"
        if [[ -f "${PRIVATE_KEY}" ]]; then
            if [[ "$(uname)" == 'Darwin' ]]; then
                # Use Keychain to retrieve passphrase.
                ssh-add --apple-load-keychain "${PRIVATE_KEY}" > /dev/null 2>&1
            else
                ssh-add "${PRIVATE_KEY}" > /dev/null 2>&1
            fi
        fi
    done
fi
