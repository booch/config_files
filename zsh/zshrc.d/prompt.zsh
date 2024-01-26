#!/bin/zsh

# This is needed to allow full Unicode support (like \uE0B0).
LC_ALL=en_US.UTF-8

# See docs at https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html.
# Note that `print -P` will also do prompt expansion.

# Enable parameter, arithmetic, and command expansion in prompts.
setopt prompt_subst

# From comment under https://superuser.com/a/974942/1264976.
# NOTE: Does not handle double-width characters.
# To handle that, see https://www.reddit.com/r/zsh/comments/cgbm24/multiline_prompt_the_missing_ingredient/.
# function prompt-length() {
#     # Reset ZSH options locally.
#     emulate -LR zsh
#     local prompt="$1"
#     echo "$(( ${#${(S%%)prompt//(\%([KF1]|)\{*\}|\%[Bbkf])}} ))"
# }

# autoload -Uz vcs_info
# zstyle ':vcs_info:*' enable git
# zstyle ':vcs_info:git:*' check-for-staged-changes true
# zstyle ':vcs_info:git:*' use-simple true
# zstyle ':vcs_info:*' use-prompt-escapes true
# zstyle ':vcs_info:*' debug true
# zstyle ':vcs_info:*' stagedstr 'STAGED!'
# zstyle ':vcs_info:*' formats       '%b'
# zstyle ':vcs_info:*' actionformats '[%b|%a]%u%c-'
# # Test with:
# vcs_info interactive; vcs_info_lastmsg


# List changed files. Compare with '' (using test -z) to see if there are any (repo is dirty).
#command git status --porcelain --untracked-files=no

# Not sure what exactly this does yet. Said my branch had no upstream.
# prompt_pure_async_git_arrows() {
# 	setopt localoptions noshwordsplit
# 	command git rev-list --left-right --count HEAD...@'{u}'
# }

# function current_branch() {
#   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
#   echo ${ref#refs/heads/}
# }
#
# function current_repository() {
#   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
#   echo $(git remote -v | cut -d':' -f 2)
# }


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
    typeset -g prompt_command_start="$(( $(print -P '%D{%s%3.}') ))"
}
prompt_preexec
prompt_precmd() {
    if (( ${+prompt_command_start} )); then
        local now="$(( $(print -P '%D{%s%3.}') ))"
        typeset -g prompt_execution_time="$(pretty_ms "$(( now - prompt_command_start ))")"
        unset prompt_command_start
    else
        unset prompt_execution_time
    fi
    typeset -g load="$(uptime | sed 's/.*load averages://' | awk '{print $1}')"
    # We'd use `git branch --show-current`, but that won't show anything if HEAD is detached. From https://stackoverflow.com/a/55276236/26311
    typeset -g git_branch="$(git symbolic-ref -q --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null || git rev-parse --short HEAD 2> /dev/null)"
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec prompt_preexec
add-zsh-hook precmd prompt_precmd

# setopt nopromptbang prompt{cr,percent,sp,subst}

SEPARATOR="$(echo '\uE0B0')"
UP="$(tput cuu1)"
DOWN="$(tput cud1)"
# Possibly useful:
SAVE_CURSOR="$(tput sc)"
RESTORE_CURSOR="$(tput rc)"

# Interpret % in prompts
export PROMPT_PERCENT=1

# Return code, # of jobs, load, runtime
# Date and time
PROMPT_RC='%(?.%K{green}.%K{red}) %? %k'
PROMPT_LOAD='%K{magenta} ${load:-} %k'
PROMPT_JOBS='%K{3} %j %k'
PROMPT_RUNTIME='%K{yellow} ${prompt_execution_time:--} %k'
PROMPT_DATE='%F{green}%K{black} %D{%F %T} %f%k'
PROMPT_DATE_LENGTH="$(( 19 + 2 ))"
PROMPT_USER_HOST="%K{black}%F{3} %n@$(hostname) %k"
PROMPT_PWD='%F{yellow}%K{blue} %2~ %f%k'
PROMPT_GIT='%F{black}%K{yellow} ${git_branch:-} %f%k'
PROMPT_GIT_LENGTH='$(( ${#git_branch:-0} + 2 ))'

ZSH_PROMPT_1_LEFT="${PROMPT_RC}${PROMPT_LOAD}${PROMPT_RUNTIME}"
ZSH_PROMPT_1_RIGHT="${PROMPT_DATE}"
ZSH_PROMPT_1="${ZSH_PROMPT_1_LEFT} \$(tput hpa \$(( \$(echo \$COLUMNS) - $PROMPT_DATE_LENGTH )) )${ZSH_PROMPT_1_RIGHT}"
ZSH_PROMPT_2_RIGHT="${PROMPT_GIT}"
ZSH_PROMPT_2="${PROMPT_USER_HOST}${PROMPT_PWD} \$(tput hpa \$(( \$(echo \$COLUMNS) - $PROMPT_GIT_LENGTH )) )${ZSH_PROMPT_2_RIGHT}"
ZSH_PROMPT_3='%(!.%F{red}#.$)%f '

export PROMPT="${ZSH_PROMPT_1}
${ZSH_PROMPT_2}
${ZSH_PROMPT_3}"



#RPROMPT="%{${UP}%}%{${UP}%}${ZSH_RPROMPT_1}%{${DOWN}%}%{${DOWN}%}"

## MANUAL TESTING of design
# GREEN="$(tput setaf 2)"
# YELLOW="$(tput setaf 3)"
# GREEN_BG="$(tput setab 2)"
# PURPLE_BG="$(tput setab 5)"
# YELLOW_BG="$(tput setab 3)"
# REVERSE="$(tput rev)"
# RESET="$(tput sgr0)"
# echo "${GREEN}\uE0B2${RESET}${GREEN_BG} 0 ${PURPLE_BG} 4.98 ${YELLOW_BG} 2145ms ${RESET}${YELLOW}${RESET}"

# echo ''

# Don't need Zsh to report timing for us.
unset REPORTTIME

# TODO: Look into setting TIMEFMT and REPORTMEMORY.
