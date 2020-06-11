#!/bin/bash

# Automatically run Ruby scripts with "bundle exec" (but only when appropriate).
# http://effectif.com/ruby/automating-bundle-exec
# Github: https://github.com/gma/bundler-exec


## Functions

bundler-installed()
{
    which bundle > /dev/null 2>&1
}

within-bundled-project()
{
    local dir="$(pwd)"
    while [ "$(dirname $dir)" != "/" ]; do
        [ -f "$dir/Gemfile" ] || [ -f "$dir/gems.rb" ] && return
        dir="$(dirname $dir)"
    done
    false
}

run-with-bundler()
{
    if [ -x "./.git/safe/../../bin/$0" ]; then
        "./.git/safe/../../bin/$@"
    elif bundler-installed && within-bundled-project; then
        bundle exec "$@"
    else
        "$@"
    fi
}

define-bundler-aliases()
{
    # Allow zsh to iterate over list of words
    [ -n "$ZSH_VERSION" ] && setopt localoptions shwordsplit

    local command

    for command in $BUNDLED_COMMANDS; do
        if [[ $command != "bundle" && $command != "gem" ]]; then
            alias $command="run-with-bundler $command"
        fi
    done
}


## Main program

# BUNDLED_COMMANDS="${BUNDLED_COMMANDS:-
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
html2haml
jasmine
jekyll
kitchen
knife
middleman
pry
rackup
rails
rake
rake2thor
rspec
ruby
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
thin
thor
tilt
tt
turn
unicorn
unicorn_rails
wagon
}"

define-bundler-aliases

unset -f define-bundler-aliases
