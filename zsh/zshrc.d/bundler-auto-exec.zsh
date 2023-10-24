#!/bin/zsh

# Automatically run Ruby scripts with "bundle exec" (but only when appropriate).
# http://effectif.com/ruby/automating-bundle-exec

# Based on Bash version: https://github.com/gma/bundler-exec
# Based on ZSH version: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/bundler/bundler.plugin.zsh


bundled_commands=(
    annotate
    cap
    capify
    chef
    chefspec
    chef-apply
    chef-client
    chef-shell
    chef-solo
    cucumber
    foodcritic
    guard
    haml
    hanami
    html2haml
    irb
    jasmine
    jekyll
    kitchen
    knife
    middleman
    nanoc
    pry
    puma
    rackup
    rails
    rainbows
    rackup
    rake
    rake2thor
    rspec
    rubocop
    sass
    sass-convert
    serve
    shotgun
    sidekiq
    solargraph
    spec
    spork
    spring
    strainer
    tailor
    taps
    thin
    thor
    tilt
    tt
    turn
    unicorn
    unicorn_rails
    wagon
)

# Remove anything in $UNBUNDLED_COMMANDS from the bundled_commands list.
for cmd in $UNBUNDLED_COMMANDS; do
    bundled_commands=(${bundled_commands#$cmd});
done

# Add anything in $BUNDLED_COMMANDS to the bundled_commands list.
for cmd in $BUNDLED_COMMANDS; do
    bundled_commands+=($cmd);
done

bundle_install() {
    if ! _bundler-installed; then
        echo "Bundler is not installed"
    elif ! _within-bundled-project; then
        echo "Can't 'bundle install' outside a bundled project"
    else
        local bundler_version=`bundle version | cut -d' ' -f3`
        if [[ $bundler_version > '1.4.0' || $bundler_version = '1.4.0' ]]; then
            if [[ "$OSTYPE" = (darwin|freebsd)* ]]; then
                local cores_num="$(sysctl -n hw.ncpu)"
            else
                local cores_num="$(nproc)"
            fi
            bundle install --jobs=$cores_num $@
        else
            bundle install $@
        fi
    fi
}

_bundler-installed() {
    which bundle > /dev/null 2>&1
}

_within-bundled-project() {
    local check_dir="$PWD"
    while [ "$check_dir" != "/" ]; do
        [ -f "$check_dir/Gemfile" -o -f "$check_dir/gems.rb" ] && return
        check_dir="$(dirname $check_dir)"
    done
    false
}

_binstubbed() {
    [ -f "./bin/${1}" ]
}

_run-with-bundler() {
    if _bundler-installed && _within-bundled-project; then
        if _binstubbed $1; then
            ./bin/${^^@}
        else
            bundle exec $@
        fi
    else
        $@
    fi
}

## Main program
for cmd in $bundled_commands; do
    eval "function unbundled_$cmd () { $cmd \$@ }"
    eval "function bundled_$cmd () { _run-with-bundler $cmd \$@}"
    alias $cmd=bundled_$cmd

    if which _$cmd > /dev/null 2>&1; then
        compdef _$cmd bundled_$cmd=$cmd
    fi
done
