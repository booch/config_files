#!/bin/bash
# Note that this may be sourced by Bash or Zsh (and probably other shells).
# It should be sourced on shell startup to set up your Mac for local development.


main() {
    asdf-setup
    docker-access
    docker-aliases
    rails-env
    rails-aliases
}

asdf-setup() {
    # TODO: Test this.
    if [[ -n $ASDF_DIR ]]; then
        source "$(brew --prefix asdf)/libexec/asdf.sh"
    fi
}

docker-access() {
    # This may already set, but it's probably nice to have it explicit.
    # TODO: Only set if it's not already set.
    export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

    # These environment variables are (roughly) from `docker-compose run api bash -c export`.

    # Access to the Docker Postgres instance.
    # If this is `localhost` or `127.0.0.1`, Postgres uses a UNIX domain socket instead of TCP. The `.` overrides that.
    export DATABASE_HOST='localhost.'
    export DATABASE_PORT='5432'
    export DATABASE_USER='postgres'
    export DATABASE_PASSWORD='secret'

    # Access to the Docker Redis instance.
    export REDIS_URL='redis://127.0.0.1:6379/'
}

docker-aliases() {
    # Allow use of Docker-installed instance of docker-compose if necessary.
    if ! command -v docker-compose > /dev/null ; then
        alias docker-compose='docker compose'
    fi

    # Bring up the app.
    # NOTE: This runs in detached mode, and you won't see any logs.
    # TODO: Explain how to look at logs or attach to an instance.
    alias up='docker-compose up --detach'

    # Easily run something in the API container.
    # Example: `api rails test test/my/file_test.rb`
    # Example: `api bash`
    alias api='docker-compose run --rm api'

    # Start up Storybook. Accessed via http://localhost:6006/.
    # alias storybook='docker-compose --profile storybook up'
    alias storybook='yarn run storybook'
}

rails-env() {
    # These need to exist, but their values don't really matter.
    export RAILS_SECRET_KEY_BASE="$(openssl rand -base64 16)"
    export AUTH_ACCESS_TOKENS_SECRET="$(openssl rand -base64 16)"
    export AUTH_REFRESH_TOKENS_SECRET="$(openssl rand -base64 16)"
    export PASSWORD_RESET_TOKENS_SECRET="$(openssl rand -base64 16)"
    export LANDING_PAGE_TOKEN_SECRET="$(openssl rand -base64 16)"
    export ACTIVATION_TOKEN_SECRET="$(openssl rand -base64 16)"
    export AUTH_DEVICE_TOKEN_SECRET="$(openssl rand -base64 16)"
}

rails-aliases() {
    # Running Rails locally works for tests, console, rake tasks, etc.
    alias rails='bundle exec rails'

    # Access Rails console in various environments.
    # See https://debtbook.atlassian.net/wiki/spaces/PD/pages/1980497924/AWS+Access+for+Engineers#Rails-Console-Access
    alias uat='rails-console-reminders ; AWS_ENV=uat aws-vault exec eng make remote_shell'
    alias int='rails-console-reminders ; AWS_ENV=int aws-vault exec eng make remote_shell'
    alias pilot='rails-console-reminders ; AWS_ENV=pilot aws-vault exec eng make remote_shell'
    alias prod='rails-console-reminders ; AWS_ENV=prod aws-vault exec admin make remote_shell'

    # TODO: Move this to print out a text file in scripts/.
    alias rails-console-reminders='echo "rails console --sandbox" ; echo "AR::Base.logger = Logger.new(STDERR)"'
}


main


# Undefine all the methods we defined, so as not to pollute your namespace.
unset -f main
unset -f asdf-setup
unset -f docker-access
unset -f docker-aliases
unset -f rails-env
unset -f rails-aliases

# Let setup-local script know that we've already been run.
export DEBTBOOK_STARTUP_SCRIPTS_RUN=1
