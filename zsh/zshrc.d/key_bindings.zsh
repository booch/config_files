#!/bin/zsh

# Add commands to ZLE.
# NOTE: Consider replacing with zsh-users/zsh-history-substring-search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Use Emacs-style keybindings.
bindkey -e

# These *had* been working in iTerm2, but then seemed to have stopped working.
bindkey '\e[1~' beginning-of-line       # Home
bindkey '\e[4~' end-of-line             # End

## ANSI escape codes.
ESC='\e'
CSI='\e['

# Define human-readable names for all special key combinations.
zmodload -F zsh/terminfo +b:echoti +p:terminfo
typeset -gA keys
keys=(
    Esc                     '\e'
    Ctrl                    '\C-'
    Meta                    '\M-'

    Ctrl+Space              '\C-@'

    Up                      "${terminfo[kcuu1]}  ${ESC}OA  ${CSI}A"
    Down                    "${terminfo[kcud1]}  ${ESC}OB  ${CSI}B"
    Right                   "${terminfo[kcuf1]}  ${ESC}OC  ${CSI}C"
    Left                    "${terminfo[kcub1]}  ${ESC}OD  ${CSI}D"
    Home                    "${ESC}OH  ${CSI}H  ${CSI}1~"
    End                     "${ESC}OF  ${CSI}F  ${CSI}4~"
    PageUp                  "${CSI}5~"
    PageDown                "${CSI}6~"

    Shift+Up                "${CSI}1;2A"
    Shift+Down              "${CSI}1;2B"
    Shift+Right             "${terminfo[kRIT]}  ${CSI}1;2C"
    Shift+Left              "${terminfo[kLFT]}  ${CSI}1;2D"
    Shift+Home              "${CSI}1;2H"
    Shift+End               "${CSI}1;2F"
    Shift+PageUp            "${CSI}5;2~"
    Shift+PageDown          "${CSI}6;2~"

    Alt+Up                  "${CSI}1;3A"
    Alt+Down                "${CSI}1;3B"
    Alt+Right               "${CSI}1;3C"
    Alt+Left                "${CSI}1;3D"
    Alt+Home                "${CSI}1;3H"
    Alt+End                 "${CSI}1;3F"
    Alt+PageUp              "${CSI}5;3~"
    Alt+PageDown            "${CSI}6;3~"

    Alt+Shift+Up            "${CSI}1;4A"
    Alt+Shift+Down          "${CSI}1;4B"
    Alt+Shift+Right         "${CSI}1;4C"
    Alt+Shift+Left          "${CSI}1;4D"
    Alt+Shift+Home          "${CSI}1;4H"
    Alt+Shift+End           "${CSI}1;4F"
    Alt+Shift+PageUp        "${CSI}5;4~"
    Alt+Shift+PageDown      "${CSI}6;4~"

    Ctrl+Up                 "${CSI}1;5A"
    Ctrl+Down               "${CSI}1;5B"
    Ctrl+Right              "${CSI}1;5C  ${CSI}1;5C  ${CSI}5C  \e${CSI}C  \eOc  \eOC"
    Ctrl+Left               "${CSI}1;5D  ${CSI}1;5D  ${CSI}5D  \e${CSI}D  \eOd  \eOD"
    Ctrl+Home               "${CSI}1;5H"
    Ctrl+End                "${CSI}1;5F"
    Ctrl+PageUp             "${CSI}5;5~"
    Ctrl+PageDown           "${CSI}6;5~"
    Ctrl+Delete             "${CSI}3;5~"

    Ctrl+Shift+Up           "${CSI}1;6A"
    Ctrl+Shift+Down         "${CSI}1;6B"
    Ctrl+Shift+Right        "${CSI}1;6C"
    Ctrl+Shift+Left         "${CSI}1;6D"
    Ctrl+Shift+Home         "${CSI}1;6H"
    Ctrl+Shift+End          "${CSI}1;6F"
    Ctrl+Shift+PageUp       "${CSI}5;6~"
    Ctrl+Shift+PageDown     "${CSI}6;6~"

    Ctrl+Alt+Up             "${CSI}1;7A"
    Ctrl+Alt+Down           "${CSI}1;7B"
    Ctrl+Alt+Right          "${CSI}1;7C"
    Ctrl+Alt+Left           "${CSI}1;7D"
    Ctrl+Alt+Home           "${CSI}1;7H"
    Ctrl+Alt+End            "${CSI}1;7F"
    Ctrl+Alt+PageUp         "${CSI}5;7~"
    Ctrl+Alt+PageDown       "${CSI}6;7~"

    Ctrl+Alt+Shift+Up       "${CSI}1;8A"
    Ctrl+Alt+Shift+Down     "${CSI}1;8B"
    Ctrl+Alt+Shift+Right    "${CSI}1;8C"
    Ctrl+Alt+Shift+Left     "${CSI}1;8D"
    Ctrl+Alt+Shift+Home     "${CSI}1;8H"
    Ctrl+Alt+Shift+End      "${CSI}1;8F"
    Ctrl+Alt+Shift+PageUp   "${CSI}5;8~"
    Ctrl+Alt+Shift+PageDown "${CSI}6;8~"

    Home                    "${terminfo[khome]}  \e[1~  \eOH  \e[H"
    End                     "${terminfo[kend]}   \e[4~  \eOF  \e[F"
    PageDown                "${terminfo[knp]}    \e[6~"
    PageUp                  "${terminfo[kpp]}    "

    Insert                  "${terminfo[kich1]}  ${CSI}2~"
    Delete                  "${terminfo[kdch1]}  ${CSI}3~"
    Backspace               "${terminfo[kbs]}"

    Shift+Insert            "${terminfo[kich1]}  ${CSI}2~"  # CUA Cut
    Shift+Delete            "${terminfo[kdch1]}  ${CSI}3~"  # CUA Paste

    Ctrl+Backspace          "${ESC}?"
    Ctrl+Del                "${CSI}3;5~"  # Delete word to the right of cursor.
    Ctrl+Ins                "${CSI}2;5~"  # CUA CopDI
    Tab                     "${terminfo[ht]}"
    Enter                   "${terminfo[kent]}"
    Space                   ' '

    Shift+Home              "${terminfo[kHOM]}"
    Shift+End               "${terminfo[kEND]}"
    Shift+PageUp            "${terminfo[kPRV]}" # Not defined in (iTerm2) terminfo
    Shift+PageDown          "${terminfo[kNXT]}" # Not defined in (iTerm2) terminfo
    Shift+Insert            "${terminfo[kIC]}"  # Not defined in (iTerm2) terminfo
    Shift+Delete            "${terminfo[kDC]}"  # Not defined in (iTerm2) terminfo
    Shift+Tab               "${terminfo[kcbt]}  ${CSI}Z" # AKA BackTab

    Alt+Enter               "\e${terminfo[kent]}"

    F1                      "${terminfo[kf1]}"
    F2                      "${terminfo[kf2]}"
    F3                      "${terminfo[kf3]}"
    F4                      "${terminfo[kf4]}"
    F5                      "${terminfo[kf5]}"
    F6                      "${terminfo[kf6]}"
    F7                      "${terminfo[kf7]}"
    F8                      "${terminfo[kf8]}"
    F9                      "${terminfo[kf9]}"
    F10                     "${terminfo[kf10]}"
    F11                     "${terminfo[kf11]}"
    F12                     "${terminfo[kf12]}"

    Shift+F1                "${terminfo[kf13]}"
    Shift+F2                "${terminfo[kf14]}"
    Shift+F3                "${terminfo[kf15]}"
    Shift+F4                "${terminfo[kf16]}"
    Shift+F5                "${terminfo[kf17]}"
    Shift+F6                "${terminfo[kf18]}"
    Shift+F7                "${terminfo[kf19]}"
    Shift+F8                "${terminfo[kf20]}"
    Shift+F9                "${terminfo[kf21]}"
    Shift+F10               "${terminfo[kf22]}"
    Shift+F11               "${terminfo[kf23]}"
    Shift+F12               "${terminfo[kf24]}"

    Ctrl+F1                 "${terminfo[kf25]}"
    Ctrl+F2                 "${terminfo[kf26]}"
    Ctrl+F3                 "${terminfo[kf27]}"
    Ctrl+F4                 "${terminfo[kf28]}"
    Ctrl+F5                 "${terminfo[kf29]}"
    Ctrl+F6                 "${terminfo[kf30]}"
    Ctrl+F7                 "${terminfo[kf31]}"
    Ctrl+F8                 "${terminfo[kf32]}"
    Ctrl+F9                 "${terminfo[kf33]}"
    Ctrl+F10                "${terminfo[kf34]}"
    Ctrl+F11                "${terminfo[kf35]}"
    Ctrl+F12                "${terminfo[kf36]}"

    Ctrl+Shift+F1           "${terminfo[kf37]}  ${CSI}1;6P  ${ESC}O6P  ${CSI}11;6~"
    Ctrl+Shift+F2           "${terminfo[kf38]}  ${CSI}1;6Q  ${ESC}O6Q  ${CSI}12;6~"
    Ctrl+Shift+F3           "${terminfo[kf39]}  ${CSI}1;6R  ${ESC}O6R  ${CSI}13;6~"
    Ctrl+Shift+F4           "${terminfo[kf40]}  ${CSI}1;6S  ${ESC}O6S  ${CSI}14;6~"
    Ctrl+Shift+F5           "${terminfo[kf41]}  ${CSI}15;6~"
    Ctrl+Shift+F6           "${terminfo[kf42]}  ${CSI}17;6~"
    Ctrl+Shift+F7           "${terminfo[kf43]}  ${CSI}18;6~"
    Ctrl+Shift+F8           "${terminfo[kf44]}  ${CSI}19;6~"
    Ctrl+Shift+F9           "${terminfo[kf45]}  ${CSI}20;6~"
    Ctrl+Shift+F10          "${terminfo[kf46]}  ${CSI}21;6~"
    Ctrl+Shift+F11          "${terminfo[kf47]}  ${CSI}23;6~"
    Ctrl+Shift+F12          "${terminfo[kf48]}  ${CSI}24;6~"

    Alt+F1                  "${terminfo[kf49]}  ${CSI}1;3P  ${ESC}O3P"
    Alt+F2                  "${terminfo[kf50]}  ${CSI}1;3Q  ${ESC}O3Q"
    Alt+F3                  "${terminfo[kf51]}  ${CSI}1;3R  ${ESC}O3R"
    Alt+F4                  "${terminfo[kf52]}  ${CSI}1;3S  ${ESC}O3S"
    Alt+F5                  "${terminfo[kf53]}  ${CSI}15;3~"
    Alt+F6                  "${terminfo[kf54]}  ${CSI}17;3~"
    Alt+F7                  "${terminfo[kf55]}  ${CSI}18;3~"
    Alt+F8                  "${terminfo[kf56]}  ${CSI}19;3~"
    Alt+F9                  "${terminfo[kf57]}  ${CSI}20;3~"
    Alt+F10                 "${terminfo[kf58]}  ${CSI}21;3~"
    Alt+F11                 "${terminfo[kf59]}  ${CSI}23;3~"
    Alt+F12                 "${terminfo[kf60]}  ${CSI}24;3~"

    Alt+Shift+F1            "${terminfo[kf61]}  ${CSI}1;4P  ${ESC}O4P"
    Alt+Shift+F2            "${terminfo[kf62]}  ${CSI}1;4Q  ${ESC}O4Q"
    Alt+Shift+F3            "${terminfo[kf63]}  ${CSI}1;4R  ${ESC}O4R"
    Alt+Shift+F4            "${terminfo[kf64]}  ${CSI}1;4S  ${ESC}O4S"
    Alt+Shift+F5            "${terminfo[kf65]}  ${CSI}15;4~"
    Alt+Shift+F6            "${terminfo[kf66]}  ${CSI}17;4~"
    Alt+Shift+F7            "${terminfo[kf67]}  ${CSI}18;4~"
    Alt+Shift+F8            "${terminfo[kf68]}  ${CSI}19;4~"
    Alt+Shift+F9            "${terminfo[kf69]}  ${CSI}20;4~"
    Alt+Shift+F10           "${terminfo[kf70]}  ${CSI}21;4~"
    Alt+Shift+F11           "${terminfo[kf71]}  ${CSI}23;4~"
    Alt+Shift+F12           "${terminfo[kf72]}  ${CSI}24;4~"

    Ctrl+Alt+F1             "${CSI}1;7P  ${ESC}O7P  ${CSI}11;7~"
    Ctrl+Alt+F2             "${CSI}1;7Q  ${ESC}O7Q  ${CSI}12;7~"
    Ctrl+Alt+F3             "${CSI}1;7R  ${ESC}O7R  ${CSI}13;7~"
    Ctrl+Alt+F4             "${CSI}1;7S  ${ESC}O7S  ${CSI}14;7~"
    Ctrl+Alt+F5             "${CSI}15;7~"
    Ctrl+Alt+F6             "${CSI}17;7~"
    Ctrl+Alt+F7             "${CSI}18;7~"
    Ctrl+Alt+F8             "${CSI}19;7~"
    Ctrl+Alt+F9             "${CSI}20;7~"
    Ctrl+Alt+F10            "${CSI}21;7~"
    Ctrl+Alt+F11            "${CSI}23;7~"
    Ctrl+Alt+F12            "${CSI}24;7~"

    Ctrl+Alt+Shift+F1       "${CSI}1;8P  ${ESC}O8P  ${CSI}11;8~"
    Ctrl+Alt+Shift+F2       "${CSI}1;8Q  ${ESC}O8Q  ${CSI}12;8~"
    Ctrl+Alt+Shift+F3       "${CSI}1;8R  ${ESC}O8R  ${CSI}13;8~"
    Ctrl+Alt+Shift+F4       "${CSI}1;8S  ${ESC}O8S  ${CSI}14;8~"
    Ctrl+Alt+Shift+F5       "${CSI}15;8~"
    Ctrl+Alt+Shift+F6       "${CSI}17;8~"
    Ctrl+Alt+Shift+F7       "${CSI}18;8~"
    Ctrl+Alt+Shift+F8       "${CSI}19;8~"
    Ctrl+Alt+Shift+F9       "${CSI}20;8~"
    Ctrl+Alt+Shift+F10      "${CSI}21;8~"
    Ctrl+Alt+Shift+F11      "${CSI}23;8~"
    Ctrl+Alt+Shift+F12      "${CSI}24;8~"
)

typeset -gA key_bindings
key_bindings=(
    Left                backward-char
    Right               forward-char
    Up                  up-line-or-beginning-search
    Down                down-line-or-beginning-search

    Home                beginning-of-line
    End                 end-of-line
    PageUp              up-line-or-history
    PageDown            down-line-or-history

    Insert              overwrite-mode
    Backspace           backward-delete-char
    Delete              delete-char

    Tab                 expand-or-complete  # ???
    BackTab             reverse-menu-complete  # ???


    Shift+Tab           undo
    Alt+/               redo

    # Shift+Left          cd-back     # CD into previous directory
    # Shift+Right         cd-forward  # CD into next directory
    # Shift+Up            cd-up       # CD into parent directory
    # Shift+Down          cd-down     # CD into a child directory
)

# for key_name ansi_sequences in ${(kv)keys}; do
#     # # Split `ansi_sequences` into an array (space-separated).
#     # ansi_sequences=($ansi_sequences)
#     # TODO: We should probably use the first ANSI sequence as canonical, instead of the key_name.
#     for ansi_seq in ${(s: :)ansi_sequences}; do
#         bindkey -s "$ansi_seq" "$key_name"
#     done
# done
#
# for key_name command in ${(kv)key_bindings}; do
#     bindkey "$key_name" "$command"
# done


typeset -gA xterm_keys
xterm_keys=(
    'Alt+Up'            '^[[1;3A'
    'Alt+Down'          '^[[1;3B'
    'Alt+Left'          '^[[1;3D'
    'Alt+Right'         '^[[1;3C'
    'Alt+Home'          '^[[1;3H'
    'Alt+End'           '^[[1;3F'
    'Alt+Delete'        '^[[3;3~'
    'Shift+Up'          '^[[1;2A'
    'Shift+Down'        '^[[1;2B'
    'Shift+Left'        '^[[1;2D'
    'Shift+Right'       '^[[1;2C'
    'Shift+Home'        '^[[1;2H'
    'Shift+End'         '^[[1;2F'
)

bindkey -s '^[Oc'     '^[[1;5C'
bindkey -s '^[Od'     '^[[1;5D'
bindkey -s '^[Oj'     '*'
bindkey -s '^[Ok'     '+'
bindkey -s '^[Ol'     '+'
bindkey -s '^[Om'     '-'
bindkey -s '^[On'     '.'
bindkey -s '^[Oo'     '/'
bindkey -s '^[Op'     '0'
bindkey -s '^[Oq'     '1'
bindkey -s '^[Or'     '2'
bindkey -s '^[Os'     '3'
bindkey -s '^[Ot'     '4'
bindkey -s '^[Ou'     '5'
bindkey -s '^[Ov'     '6'
bindkey -s '^[Ow'     '7'
bindkey -s '^[Ox'     '8'
bindkey -s '^[Oy'     '9'

bindkey -s '^[OA'     '^[[A'
bindkey -s '^[OB'     '^[[B'
bindkey -s '^[OC'     '^[[C'
bindkey -s '^[OD'     '^[[D'
bindkey -s '^[OF'     '^[[F'
bindkey -s '^[OH'     '^[[H'
bindkey -s '^[OM'     '^M'  # Enter
bindkey -s '^[OX'     '='

bindkey -s '^[[1~'    '^[[H'
bindkey -s '^[[4~'    '^[[F'
bindkey -s '^[[7~'    '^[[H'
bindkey -s '^[[8~'    '^[[F'

bindkey -s '^[^[[D'   '^[[1;3D'
bindkey -s '^[^[[C'   '^[[1;3C'

bindkey -s '^[[3\^'   '^[[3;5~'
bindkey -s '^[^[[3~'  '^[[3;3~'
bindkey -s '^[[1;9D'  '^[[1;3D'
bindkey -s '^[[1;9C'  '^[[1;3C'

# Translate application mode cursor keys to raw mode cursor keys.
bindkey -s '^[OA'     '^[[A'    # up
bindkey -s '^[OB'     '^[[B'    # down
bindkey -s '^[OD'     '^[[D'    # left
bindkey -s '^[OC'     '^[[C'    # right
bindkey -s '^[OH'     '^[[H'    # home
bindkey -s '^[OF'     '^[[F'    # end

# Urxvt: translate to xterm equivalents.
bindkey -s '^[[7~'    '^[[H'    # home
bindkey -s '^[[8~'    '^[[F'    # end
bindkey -s '^[Oa'     '^[[1;5A' # ctrl+up
bindkey -s '^[Ob'     '^[[1;5B' # ctrl+down
bindkey -s '^[Od'     '^[[1;5D' # ctrl+left
bindkey -s '^[Oc'     '^[[1;5C' # ctrl+right
bindkey -s '^[[7\^'   '^[[1;5H' # ctrl+home
bindkey -s '^[[8\^'   '^[[1;5F' # ctrl+end
bindkey -s '^[[3\^'   '^[[3;5~' # ctrl+delete
bindkey -s '^[^[[A'   '^[[1;3A' # alt+up
bindkey -s '^[^[[B'   '^[[1;3B' # alt+down
bindkey -s '^[^[[D'   '^[[1;3D' # alt+left
bindkey -s '^[^[[C'   '^[[1;3C' # alt+right
bindkey -s '^[^[[7~'  '^[[1;3H' # alt+home
bindkey -s '^[^[[8~'  '^[[1;3F' # alt+end
bindkey -s '^[^[[3~'  '^[[3;3~' # alt+delete
bindkey -s '^[[a'     '^[[1;2A' # shift+up
bindkey -s '^[[b'     '^[[1;2B' # shift+down
bindkey -s '^[[d'     '^[[1;2D' # shift+left
bindkey -s '^[[c'     '^[[1;2C' # shift+right
bindkey -s '^[[7$'    '^[[1;2H' # shift+home
bindkey -s '^[[8$'    '^[[1;2F' # shift+end

# Tmux: translate to xterm equivalents.
bindkey -s '^[[1~'    '^[[H'    # home
bindkey -s '^[[4~'    '^[[F'    # end
bindkey -s '^[^[[A'   '^[[1;3A' # alt+up
bindkey -s '^[^[[B'   '^[[1;3B' # alt+down
bindkey -s '^[^[[D'   '^[[1;3D' # alt+left
bindkey -s '^[^[[C'   '^[[1;3C' # alt+right
bindkey -s '^[^[[1~'  '^[[1;3H' # alt+home
bindkey -s '^[^[[4~'  '^[[1;3F' # alt+end
bindkey -s '^[^[[3~'  '^[[3;3~' # alt+delete

# iTerm2: translate to xterm equivalents.
# Missing (depending on settings): ctrl+{up,down,left,right}, {ctrl,alt}+{delete,backspace}.
bindkey -s '^[^[[A'   '^[[1;3A' # alt+up
bindkey -s '^[^[[B'   '^[[1;3B' # alt+down
bindkey -s '^[^[[D'   '^[[1;3D' # alt+left
bindkey -s '^[^[[C'   '^[[1;3C' # alt+right
bindkey -s '^[[1;9A'  '^[[1;3A' # alt+up
bindkey -s '^[[1;9B'  '^[[1;3B' # alt+down
bindkey -s '^[[1;9D'  '^[[1;3D' # alt+left
bindkey -s '^[[1;9C'  '^[[1;3C' # alt+right
bindkey -s '^[[1;9H'  '^[[1;3H' # alt+home
bindkey -s '^[[1;9F'  '^[[1;3F' # alt+end

# Actual key bindings.
bindkey '^[F'    'end-of-line'
bindkey '^[H'    'beginning-of-line'
bindkey '^[3~'   'delete-char'
bindkey '^[3;5~' 'kill-word'
bindkey '^[3;3~' 'kill-word'
bindkey '^['     'backward-kill-line'
bindkey '^['     'backward-kill-line'
bindkey '^['     'kill-buffer'
bindkey '^['     'kill-buffer'
bindkey '^['     'redo'
bindkey '^[1;3D' 'backward-word'
bindkey '^[1;5D' 'backward-word'
bindkey '^[1;3C' 'forward-word'
bindkey '^[1;5C' 'forward-word'

bindkey '^P'      up-line-or-beginning-search    # ctrl+p
bindkey '^[[A'    up-line-or-beginning-search    # up
bindkey '^[[1;5A' up-line-or-beginning-search    # ctrl+up
bindkey '^N'      down-line-or-beginning-search  # ctrl+n
bindkey '^[[B'    down-line-or-beginning-search  # down
bindkey '^[[1;5B' down-line-or-beginning-search  # ctrl+down

bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

bindkey '^[[D'  backward-char                       # left
bindkey '^[[C'  forward-char                        # right

bindkey '^[[H'    beginning-of-line                 # home
bindkey '^[[F'    end-of-line                       # end

bindkey '^[[1;5H' beginning-of-buffer-or-history    # ctrl+home
bindkey '^[[1;3H' beginning-of-buffer-or-history    # alt+home
bindkey '^[[1;5F' end-of-buffer-or-history          # ctrl+end
bindkey '^[[1;3F' end-of-buffer-or-history          # alt+end

# Delete the character under the cursor.
bindkey '^D'      delete-char                    # ctrl+d
bindkey '^[[3~'   delete-char                    # delete
# Delete next word.
bindkey '^[d'     kill-word                  # alt+d
bindkey '^[D'     kill-word                  # alt+D
bindkey '^[[3;5~' kill-word                  # ctrl+del
bindkey '^[[3;3~' kill-word                  # alt+del
# Delete previous word.
bindkey '^W'      backward-kill-word         # ctrl+w
bindkey '^[^?'    backward-kill-word         # alt+bs
bindkey '^[^H'    backward-kill-word         # ctrl+alt+bs

# # Move cursor one zsh word forward.
# bindkey '^[[1;6C' z4h-forward-zword              # ctrl+shift+right
# # Move cursor one zsh word backward.
# bindkey '^[[1;6D' z4h-backward-zword             # ctrl+shift+left
# # Delete next zsh word.
# bindkey '^[[3;6~' z4h-kill-zword                 # ctrl+shift+del

# Delete line before cursor.
bindkey '^[k'     backward-kill-line             # alt+k
bindkey '^[K'     backward-kill-line             # alt+K
# Delete all lines.
bindkey '^[j'     kill-buffer                    # alt+j
bindkey '^[J'     kill-buffer                    # alt+J
# # Push buffer to ephemeral history (won't be saved to HISTFILE) and delete all lines.
# bindkey '^[o'     z4h-stash-buffer               # alt+o
# bindkey '^[O'     z4h-stash-buffer               # alt+O
# # Accept autosuggestion.
# bindkey '^[m'     z4h-autosuggest-accept         # alt+m
# bindkey '^[M'     z4h-autosuggest-accept         # alt+M
# Undo and redo.
bindkey '^[[Z'    undo                           # shift+tab
bindkey '^[/'     redo                           # alt+/
# # Expand alias/glob/parameter.
# bindkey '^ '      z4h-expand                     # ctrl+space
# # Generic command completion.
# bindkey '^I'      z4h-fzf-complete               # tab
# # Command history.
# bindkey '^R'      z4h-fzf-history                # ctrl+r
# Show help for the command at cursor.
bindkey '^[h'     run-help                       # alt+h
bindkey '^[H'     run-help                       # alt+H
# # Do nothing (better than printing '~').
# bindkey '^[[5~'   z4h-do-nothing                 # pageup
# bindkey '^[[6~'   z4h-do-nothing                 # pagedown

# Move cursor one word backward.
bindkey '^[b'     backward-word              # alt+b
bindkey '^[B'     backward-word              # alt+B
bindkey '^[[1;3D' backward-word              # alt+left
bindkey '^[[1;5D' backward-word              # ctrl+left

# Move cursor one word forward.
bindkey '^[f'     forward-word               # alt+f
bindkey '^[F'     forward-word               # alt+F
bindkey '^[[1;3C' forward-word               # alt+right
bindkey '^[[1;5C' forward-word               # ctrl+right

# # cd into the previous directory.
# bindkey '^[[1;2D' z4h-cd-back                    # shift+left
# # cd into the next directory.
# bindkey '^[[1;2C' z4h-cd-forward                 # shift+right
# # cd into the parent directory.
# bindkey '^[[1;2A' z4h-cd-up                      # shift+up
# if (( _z4h_use[fzf] )); then
#   # cd into a subdirectory (interactive).
#   bindkey '^[[1;2B' z4h-cd-down                    # shift+down
# fi

# # Directory history.
# bindkey '^[r'     z4h-fzf-dir-history            # alt+r
# bindkey '^[R'     z4h-fzf-dir-history            # alt+R

# if (( _z4h_can_save_restore_screen )) &&
#    zstyle -T :z4h: prompt-at-bottom; then
bindkey '^L'      clear-screen   # ctrl+l
#   bindkey '^[^L'    z4h-clear-screen-hard-bottom   # ctrl+alt+l
# else
#   bindkey '^L'      z4h-clear-screen-soft-top      # ctrl+l
#   bindkey '^[^L'    z4h-clear-screen-hard-top      # ctrl+alt+l
# fi