#!/bin/zsh

# If we stop console output with Ctrl+S, allow any key to restart the output.
stty ixany


# If the terminal supports xterm-style setting of the title, set it to user@host:dir after every command.
# case "$TERM" in
# xterm*|rxvt*|putty*)
#     PROMPT_COMMAND="${PROMPT_COMMAND:-:} echo -ne \"\\033]0;${USER}@${HOSTNAME%%.*}: \${PWD/\$HOME/~}\\007\" ;"
#     ;;
# *)
#     ;;
# esac

# Get the terminal answerback string.
# I configure iTerm to return "iterm2".
terminal_answerback() {
    local ENQ="$(printf '\005')"
    local original_stty="$(stty -g)"
    local answerback
    # Set raw mode (don't process control characters); don't print typed characters; don't require any characters to be read; time out after 0.5 seconds.
    stty raw -echo min 0 time 5
    echo -ne "$ENQ" > /dev/tty && read -s answerback
    stty cooked
    stty "$original_stty"
    echo "$answerback"
}
TERMINAL_ANSWERBACK="$(terminal_answerback)"

## Handle PuTTY oddities.
# PuTTY's default answerback string is "PuTTY", without a terminating return character.
if [[ "$TERMINAL_ANSWERBACK" == 'PuTTY' ]]; then
    # Use a PuTTY-specific terminal type if we can.
    if [[ -f '/usr/share/terminfo/p/putty-256color' ]]; then
        export TERM='putty-256color'
    elif [[ -f '/usr/share/terminfo/p/putty' ]]; then
        export TERM='putty'
    else
        export TERM='xterm'
    fi

    # Enable UTF-8 in PuTTY (from http://www.earth.li/~huggie/blog/tech/mobile/putty-utf-8-trick.html).
    # The \e%G sets UTF-8 mode; \e[?47h and \e[?47l switch to the alternative screen and back.
    echo -ne '\e%G\e[?47h\e%G\e[?47l'
fi
