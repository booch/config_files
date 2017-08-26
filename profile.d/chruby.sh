if [[ -d /usr/local/share/chruby ]]; then
    # We have to source this, because it's implemented as a shell function.
    source /usr/local/share/chruby/chruby.sh

    # Automatically change Ruby versions when changing directories.
    source /usr/local/share/chruby/auto.sh

    # See if we need to change Ruby versions for the directory we're in now.
    [[ -r ~/.ruby-version ]] && chruby $(cat ~/.ruby-version)
    [[ -r ./.ruby-version ]] && chruby $(cat ./.ruby-version)
fi
