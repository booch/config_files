# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# NOTE: Powelevel10k is completely backweards-compatible with Powelevel9k; hence the variable names.

# Load p10k.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Define what to show in the prompt.
# p9k default = (context dir vcs) / (status root_indicator background_jobs history time).
# p10k default = (dir vcs newline prompt_char) / (status command_execution_time background_jobs direnv++ kubecontext++ context)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir newline status prompt_char)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time load vcs)

# Always show username and hostname.
POWERLEVEL9K_ALWAYS_SHOW_CONTEXT='true'
unset POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION

# Always show status of last result.
POWERLEVEL9K_STATUS_OK='true'
POWERLEVEL9K_STATUS_BACKGROUND='none'
POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND='9'
POWERLEVEL9K_CONTEXT__FOREGROUND='9'
POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND='9'

# Load our custom settings.
p10k reload
