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

ln -sf config_files/inputrc           ~/.inputrc

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

ln -sf config_files/psqlrc            ~/.psqlrc

if [ "$(uname)"x = "Darwin"x  ]; then
  mkdir -p ~/Library/KeyBindings
  ln -f DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict

  ln -sf "$HOME/config_files/karabiner.xml" "$HOME/Library/Application Support/Karabiner/private.xml"

  ln -sf "$HOME/config_files/sublime/Preferences.sublime-settings" "$HOME/Library/Application Support/Sublime Text 3/Packages/User/Preferences.sublime-settings"
  ln -sf "$HOME/config_files/sublime/Package Control.sublime-settings" "$HOME/Library/Application Support/Sublime Text 3/Packages/User/Package Control.sublime-settings"
  ln -sf "$HOME/config_files/sublime/Ruby.sublime-settings" "$HOME/Library/Application Support/Sublime Text 3/Packages/User/Ruby.sublime-settings"
  # ln -sf "$HOME/config_files/sublime/Default (OSX).sublime-keymap" "$HOME/Library/Application Support/Sublime Text 3/Packages/User/Default (OSX).sublime-keymap"
fi


# TODO: Need more permission changes?
chmod go-rwx ~/.*_history
