#!/bin/bash
#!/bin/zsh
# This file gets sourced by both Bash and Zsh startup scripts.

# If we stop console output with Ctrl+S, allow any key to restart the output.
stty ixany

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

# NOTE: Apple Terminal.app returns "Apple_Terminal".
# TODO: Also check that the terminfo exists, or fall back to xterm-truecolor, xterm-256color, iterm, or xterm.
# TODO: See https://stackoverflow.com/a/76107983 and https://iterm2.com/utilities/it2check to better determine if we're running iTerm.
# NOTE: If we're in tmux, we'll get "tmux".
if [[ "$TERM_PROGRAM" == 'iTerm.app' ]]; then
    # export TERM='iterm-truecolor'
    # export TERM='iterm-direct' # This one exists in Homebrew ncurses.
    export TERM='xterm-256color'
    export TERM='iterm'
fi

# Set COLORTERM; some terminal programs use it.
case $TERM in
    *-truecolor | vte*)
        export COLORTERM='truecolor' ;;
    *-256color)
        export COLORTERM='256color' ;;
esac

# # If the terminal supports xterm-style setting of the title, set it to user@host:dir after every command.
# # TODO: This doesn't catch most terminals that support this. Is there a terminfo entry we can check?
# case "$TERM" in
# xterm*|rxvt*|putty*)
#    PROMPT_COMMAND="${PROMPT_COMMAND:-:} echo -ne \"\\033]0;${USER}@${HOSTNAME%%.*}: \${PWD/\$HOME/~}\\007\" ;"
#    ;;
# *)
#    ;;
# esac
# # Or set the window title to the current directory.
# function settitle() { echo -ne "\033]2;$@\a\033]1;$@\a"; }
# function cd() { command cd "$@"; settitle `pwd -P`; }


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
