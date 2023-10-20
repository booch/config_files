#!/bin/bash

[[ -f "$HOME/.npmrc" ]] && export NPM_TOKEN=$(grep '//registry.npmjs.org/' <"$HOME/.npmrc" | cut -d '=' -f 2)
