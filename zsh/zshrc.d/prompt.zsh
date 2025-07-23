#!/bin/zsh

# Allow full Unicode support.
export LC_ALL=en_US.UTF-8

# Possibly useful glyphs (requires Nerd Fonts).
TRIANGLE_RIGHT=$'\uE0B0'        # 
TRIANGLE_LEFT=$'\uE0B2'         # 
ROUNDED_RIGHT=$'\uE0B4'         # 
ROUNDED_LEFT=$'\uE0B6'          # 
LOWER_TRIANGLE_RIGHT=$'\uE0B8'  # 
LOWER_TRIANGLE_LEFT=$'\uE0BA'   # 

# Possibly useful ANSI escape sequences. (We're using Zsh % prompt expansion instead.)
UP="$(tput cuu1)"
DOWN="$(tput cud1)"
SAVE_CURSOR="$(tput sc)"
RESTORE_CURSOR="$(tput rc)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
GREEN_BG="$(tput setab 2)"
YELLOW_BG="$(tput setab 3)"
PURPLE_BG="$(tput setab 5)"
REVERSE="$(tput rev)"
RESET="$(tput sgr0)"


# See docs at https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html.
# Note that `print -P` will also do prompt expansion.

# Enable parameter, arithmetic, and command expansion in prompts.
setopt prompt_subst
# Interpret `%` in prompts, but not `!`.
setopt prompt_percent no_prompt_bang

# Don't need Zsh to report timing for us. TODO: Look into setting TIMEFMT and REPORTMEMORY.
unset REPORTTIME


# Given an amount of time in milliseconds, print with the most reasonable units.
pretty_ms() {
    local ms="$1"
    if [[ $ms -lt 1000 ]]; then
        printf '%d ms' "$ms"
    elif [[ $ms -lt $((60 * 1000)) ]]; then
        printf '%.2f s' $((ms / 1000.0))
    elif [[ $ms -lt $((60 * 60 * 1000)) ]] ; then
        printf '%.2f min' $((ms / (60 * 1000.0)))
    elif [[ $ms -lt $((24 * 60 * 60 * 1000)) ]]; then
        printf '%.2f hr' $((ms / (60 * 60 * 1000.0)))
    else
        printf '%.2f day' $((ms / (24 * 60 * 60 * 1000.0)))
    fi
}


# Get execution time of each command that is run. Adapted from https://gist.github.com/knadh/123bca5cfdae8645db750bfb49cb44b0
# NOTE: We can get the full command from $1 (or $2 or $3).
prompt_preexec() {
    typeset -g prompt_command_start="$(print -P '%D{%s%3.}')"
}

# Get all the info we need for the prompt.
prompt_precmd() {
    if (( ${+prompt_command_start} )); then
        local now="$(print -P '%D{%s%3.}')"
        typeset -g prompt_execution_time="$(pretty_ms "$(( now - prompt_command_start ))")"
        unset prompt_command_start
    else
        unset prompt_execution_time
    fi
    # We'd use `git branch --show-current`, but that won't show anything if HEAD is detached. From https://stackoverflow.com/a/55276236/26311
    typeset -g prompt_git_branch="$(git symbolic-ref -q --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null || git rev-parse --short HEAD 2> /dev/null)"
    [[ -n $prompt_git_branch ]] && prompt_git_branch=" ${prompt_git_branch} "
    typeset -g prompt_load=" $(uptime | sed 's/.*load averages://' | awk '{print $1}') "
    typeset -g prompt_rc=" $(print -P '%?') "
    typeset -g prompt_runtime=" ${prompt_execution_time:--} "
    typeset -g prompt_datetime=" $(print -P '%D{%F %T}') "
    typeset -g prompt_user_host=" $(print -P '%n@$(hostname)') "
    typeset -g prompt_pwd=" $(print -P '%2~') "
    typeset -g prompt_ruby=" $(mise current ruby 2> /dev/null) "
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec prompt_preexec
add-zsh-hook precmd prompt_precmd


# Return code, # of jobs, load, runtime ... Date and time
ZSH_PROMPT_1_LEFT='%(?.%K{green}.%K{red})${prompt_rc}%K{magenta}${prompt_load}%K{yellow}${prompt_runtime}%f%k'
ZSH_PROMPT_1_RIGHT='%F{green}%K{black}${prompt_datetime}%f%k'
ZSH_PROMPT_1_SPACES='$(( ${COLUMNS} - ${#prompt_load} - ${#prompt_rc} - ${#prompt_runtime} - ${#prompt_datetime} ))'
ZSH_PROMPT_1="${ZSH_PROMPT_1_LEFT}%K{black}\${(l:$ZSH_PROMPT_1_SPACES:)}${ZSH_PROMPT_1_RIGHT}"

# User, host, current directory ... Ruby version, Git branch
ZSH_PROMPT_2_LEFT='%K{black}%F{3}${prompt_user_host}%F{yellow}%K{blue}${prompt_pwd}%f%k'
ZSH_PROMPT_2_RIGHT='%F{black}%K{red}${prompt_ruby}%K{yellow}${prompt_git_branch}%f%k'
ZSH_PROMPT_2_SPACES='$(( ${COLUMNS} - ${#prompt_user_host} - ${#prompt_pwd} - ${#prompt_git_branch} - ${#prompt_ruby} ))'
ZSH_PROMPT_2="${ZSH_PROMPT_2_LEFT}%K{black}\${(l:$ZSH_PROMPT_2_SPACES:)}${ZSH_PROMPT_2_RIGHT}"

# Red `#` if root, green `$` if not
ZSH_PROMPT_3='%(!.%F{red}#.$)%f '

export PROMPT="${ZSH_PROMPT_1}
${ZSH_PROMPT_2}
${ZSH_PROMPT_3}"
