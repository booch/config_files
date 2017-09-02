if [[ -d /usr/local/share/chruby ]]; then
    # We have to source this, because it's implemented as a shell function.
    source /usr/local/share/chruby/chruby.sh

    # Automatically change Ruby versions when changing directories.
    source /usr/local/share/chruby/auto.sh

    # Change Ruby version for the directory we're in now.
    unset RUBY_AUTO_VERSION
    chruby_auto
fi
