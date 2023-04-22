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


## Handle PuTTY oddities.

# Get the first 5 characters of the terminal answerback string. (PuTTY's default answerback string is "PuTTY", without a terminating return character.)
# NOTE: It's `read -k5` for ZSH, and `read -n5` for Bash.
echo -ne '\005' ; read -s -t1 -k5 TERMINAL_ANSWERBACK

# See if we got the PuTTY answerback.
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
