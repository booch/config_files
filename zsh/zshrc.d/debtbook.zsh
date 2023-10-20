#!/bin/zsh


# These are (roughly) from `docker-compose run api bash -c export`.
export DATABASE_HOST='127.0.0.1'
export DATABASE_USER='postgres'
export DATABASE_PASSWORD='secret'
# NOTE: We need to expose the port on the redis container.
export REDIS_URL='redis://127.0.0.1:6379/'

export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

export RAILS_SECRET_KEY_BASE="$(openssl rand -base64 16)"
export AUTH_ACCESS_TOKENS_SECRET="$(openssl rand -base64 16)"
export AUTH_REFRESH_TOKENS_SECRET="$(openssl rand -base64 16)"
export PASSWORD_RESET_TOKENS_SECRET="$(openssl rand -base64 16)"
export LANDING_PAGE_TOKEN_SECRET="$(openssl rand -base64 16)"
export ACTIVATION_TOKEN_SECRET="$(openssl rand -base64 16)"
export AUTH_DEVICE_TOKEN_SECRET="$(openssl rand -base64 16)"

alias rails='bundle exec rails'
alias api='docker-compose run --rm api'
alias up='docker-compose up'
alias storybook='docker-compose --profile storybook up'
