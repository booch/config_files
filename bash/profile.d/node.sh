[ -f "$HOME/.npmrc" ] && export NPM_TOKEN=$(cat ~/.npmrc | grep '//registry.npmjs.org/' | cut -d '=' -f 2)

