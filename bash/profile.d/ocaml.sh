# OPAM configuration (from .opam/opam-init/init.zsh)
OPAM_INIT="$HOME/.opam/opam-init"
if [ -t 0 ]; then
    test -r "$OPAM_INIT/complete.sh" && . "$OPAM_INIT/complete.sh" > /dev/null 2> /dev/null || true
    test -r "$OPAM_INIT/env_hook.sh" && . "$OPAM_INIT/env_hook.sh" > /dev/null 2> /dev/null || true
fi
test -r "$OPAM_INIT/variables.sh" && . "$OPAM_INIT/variables.sh" > /dev/null 2> /dev/null || true

# Use the nice utop REPL, instead of the default crappy REPL.
function _ocaml {
    if [[ "$#" -eq 0 ]]; then
        utop
    else
        \ocaml "$@"
    fi
}
alias ocaml=_ocaml
