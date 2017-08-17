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
ln -sf config_files/ackrc             ~/.ackrc

ln -sf config_files/bash_aliases      ~/.bash_aliases
ln -sf config_files/bash_logout       ~/.bash_logout
ln -sf config_files/bash_profile      ~/.bash_profile
ln -sf config_files/bashrc            ~/.bashrc
ln -sf config_files/profile           ~/.profile
mkdir -p ~/.profile.d
for profile_file in $(find -L profile.d -type f); do
  ln -sf ../config_files/$profile_file ~/.profile.d/
done
ln -sf config_files/profile.d         ~/.profile.d

rm -rf ~/.bundle
ln -sf config_files/bundle            ~/.bundle
ln -sf config_files/gemrc             ~/.gemrc
ln -sf config_files/irbrc             ~/.irbrc
ln -sf config_files/aprc              ~/.aprc
ln -sf config_files/railsrc           ~/.railsrc
ln -sf config_files/ruby-version      ~/.ruby-version
ln -sf config_files/rubocop.yml       ~/.rubocop.yml
ln -sf config_files/eslintrc.yml      ~/.eslintrc.yml
ln -sf config_files/jscsrc            ~/.jscsrc
ln -sf config_files/jshintrc          ~/.jshintrc

ln -sf config_files/gitconfig         ~/.gitconfig
ln -sf config_files/gitignore         ~/.gitignore
ln -sf config_files/gitattributes     ~/.gitattributes

ln -sf config_files/inputrc           ~/.inputrc

mkdir -p ~/.docker
ln -sf ../config_files/docker/config.json ~/.docker/config.json

rm -rf ~/.mc
ln -sf ../config_files/mc             ~/.mc

rm -rf ~/.nano
ln -sf config_files/nanorc            ~/.nanorc
ln -sf config_files/nano              ~/.nano

rm -rf ~/.vim
ln -sf config_files/vimrc             ~/.vimrc
ln -sf config_files/vim               ~/.vim
if [ ! -d vim/bundle/vundle ]; then
  git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
fi
mkdir -p ~/.vim/backup  # Make sure there's a global backup directory for vim.
# Install and update Vundle bundles.
if command -v vim >/dev/null 2>&1 ; then
  vim -c 'VundleInstall' -c 'VundleUpdate' -c 'qa!'
fi

mkdir -p ~/.atom
ln -sf ../config_files/atom/config.cson  ~/.atom/config.cson
ln -sf ../config_files/atom/keymap.cson  ~/.atom/keymap.cson

ln -sf config_files/psqlrc            ~/.psqlrc

if [ "$(uname)"x = "Darwin"x  ]; then
  mkdir -p ~/Library/KeyBindings
  ln -f DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict

  mkdir -p "$HOME/.config/karabiner"
  ln -sf "$HOME/config_files/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
fi


# TODO: Need more permission changes?
touch ~/.bash_history
chmod go-rwx ~/.*_history
