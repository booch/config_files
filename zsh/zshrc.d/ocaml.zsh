# OPAM configuration (from .opam/opam-init/init.zsh)
OPAM_INIT="$HOME/.opam/opam-init"
if [[ -o interactive ]]; then
    [[ ! -r "$OPAM_INIT/complete.zsh" ]] || source "$OPAM_INIT/complete.zsh"  > /dev/null 2> /dev/null
    [[ ! -r "$OPAM_INIT/env_hook.zsh" ]] || source "$OPAM_INIT/env_hook.zsh"  > /dev/null 2> /dev/null
fi
[[ ! -r "$OPAM_INIT/variables.sh" ]] || source "$OPAM_INIT/variables.sh"  > /dev/null 2> /dev/null

# Use the nice utop REPL, instead of the default crappy REPL.
function _ocaml {
    if [[ "$#" -eq 0 ]]; then
        utop
    else
        \ocaml "$@"
    fi
}
alias ocaml=_ocaml
