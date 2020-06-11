#!/bin/sh

# Make certain we're in the config_files directory.
cd "$(dirname $0)"

# Get full path to config_files directory.
CWD="$(pwd)"

# Get full list of config files.
FILES="$(ls -1A | grep -v README | grep -v install.sh | grep -v BACKUPS)"

# Get today's date in YYYYMMDD format.
TODAY="$(date +'%Y%m%d')"

# FIXME: should be ! -e
#if [ ! -e ~/BACKUPS-$TODAY ]; then
#  mkdir -p ~/BACKUPS-$TODAY
#  for file in $FILES; do
#    # TODO: Back up current config files to BACKUPS dir.
#    echo Need to back up ~/.$file to ~/BACKUPS-$TODAY/$file
#    cp -a ~/.$file ~/BACKUPS-$TODAY/$file
#  done
#fi

# Link files to where they belong.
ln -sf $CWD/ack/ackrc                           ~/.ackrc

mkdir -p ~/.zsh/custom/themes
if [ ! -d ~/.zsh/custom/themes/powerlevel10k ]; then
    git clone https://github.com/romkatv/powerlevel10k.git ~/.zsh/custom/themes/powerlevel10k
fi
ln -sf $CWD/zsh/zshrc                           ~/.zshrc
ln -sF $CWD/zsh/zshrc.d                         ~/.zsh/zshrc.d

ln -sf $CWD/bash/aliases                        ~/.bash_aliases
ln -sf $CWD/bash/bash_logout                    ~/.bash_logout
ln -sf $CWD/bash/bash_profile                   ~/.bash_profile
ln -sf $CWD/bash/bashrc                         ~/.bashrc
ln -sf $CWD/bash/profile                        ~/.profile
ln -sF $CWD/bash/profile.d                      ~/.profile.d
ln -sf $CWD/bash/inputrc                        ~/.inputrc

mkdir -p ~/.bundle
ln -sf $CWD/ruby/bundler/config                 ~/.bundle/config
ln -sf $CWD/ruby/gemrc                          ~/.gemrc
ln -sf $CWD/ruby/irbrc                          ~/.irbrc
ln -sf $CWD/ruby/pryrc                          ~/.pryrc
ln -sf $CWD/ruby/aprc                           ~/.aprc
ln -sf $CWD/ruby/railsrc                        ~/.railsrc
ln -sf $CWD/ruby/ruby-version                   ~/.ruby-version
ln -sf $CWD/ruby/rubocop.yml                    ~/.rubocop.yml

ln -sf $CWD/js/eslintrc.yml                     ~/.eslintrc.yml
ln -sf $CWD/js/jscsrc                           ~/.jscsrc
ln -sf $CWD/js/jshintrc                         ~/.jshintrc

ln -sf $CWD/racket/racketrc                     ~/.racketrc

ln -sf $CWD/markdown/markdownlint.yaml          ~/.markdownlint.yaml

mkdir -p ~/.config
ln -sF $CWD/git                                 ~/.config/git
ln -sF $CWD/tmuxinator                          ~/.config/tmuxinator

ln -sf $CWD/spelling/dictionary.txt             ~/Library/Spelling/LocalDictionary

ln -sf $CWD/ctags                               ~/.ctags

mkdir -p ~/.docker
ln -sf $CWD/docker/config.json                  ~/.docker/config.json

ln -sF $CWD/mc                                  ~/.mc

ln -sf $CWD/nano/nanorc                         ~/.nanorc
ln -sF $CWD/nano                                ~/.nano

ln -sf $CWD/vim/vimrc                           ~/.vimrc
ln -sF $CWD/vim                                 ~/.vim
if [ ! -d vim/bundle/vundle ]; then
    git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
fi
mkdir -p ~/.vim/backup  # Make sure there's a global backup directory for vim.
# Install and update Vundle bundles.
if command -v vim >/dev/null 2>&1 ; then
    vim -c 'VundleInstall' -c 'VundleUpdate' -c 'qa!'
fi

mkdir -p ~/.atom
ln -sf $CWD/atom/config.cson                    ~/.atom/config.cson
ln -sf $CWD/atom/keymap.cson                    ~/.atom/keymap.cson
ln -sf $CWD/atom/touchbar.js                    ~/.atom/packages/touchbar-utility/lib/configuration.js

ln -sf $CWD/postgresql/psqlrc                   ~/.psqlrc

if [ "$(uname)"x = "Darwin"x  ]; then
    mkdir -p ~/Library/KeyBindings
    ln -f $CWD/keyboard/DefaultKeyBinding.Dict  ~/Library/KeyBindings/DefaultKeyBinding.Dict

    mkdir -p ~/.config/karabiner
    ln -sf $CWD/keyboard/karabiner.json         ~/.config/karabiner/karabiner.json
fi


# TODO: Need more permission changes?
touch ~/.bash_history
chmod go-rwx ~/.*_history
