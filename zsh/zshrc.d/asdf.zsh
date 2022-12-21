if [[ -d $(brew --prefix asdf) ]]; then
    # We have to source this, because it's implemented as a shell function.
    source $(brew --prefix asdf)/libexec/asdf.sh
fi
