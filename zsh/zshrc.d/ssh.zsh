
# Start up SSH Agent
eval "$(ssh-agent -s)"

# Add SSH key to SSH agent.
if [[ "$(uname)" == 'Darwin' ]]; then
    # Use Keychain to retrieve passphrase.
    ssh-add --apple-load-keychain ~/.ssh/id_ed25519
else
    ssh-add ~/.ssh/id_ed25519
fi

