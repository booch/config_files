#!/bin/sh

# Make certain we're in the config_files directory.
cd `dirname $0`

# Get full path to config_files directory.
CWD=`pwd`

# Get full list of config files.
FILES=`ls -1A | grep -v README | grep -v install.sh | grep -v BACKUPS`

# Get today's date in YYYYMMDD format.
TODAY=`date +'%Y%m%d'`

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
ln -f ackrc             ~/.ackrc
ln -f aprc              ~/.aprc
ln -f bash_aliases      ~/.bash_aliases
ln -f bash_logout       ~/.bash_logout
ln -f bash_profile      ~/.bash_profile
ln -f bashrc            ~/.bashrc
ln -f gemrc             ~/.gemrc
ln -f gitignore         ~/.gitignore
ln -f inputrc           ~/.inputrc
ln -f irbrc             ~/.irbrc
mkdir -p ~/.mc
ln -f mc/ini            ~/.mc/ini
ln -f nanorc            ~/.nanorc
mkdir -p ~/.nano
ln -f nano/css.nanorc   ~/.nano/css.nanorc
ln -f nano/php.nanorc   ~/.nano/php.nanorc
ln -f nano/xml.nanorc   ~/.nano/xml.nanorc
ln -f profile           ~/.profile
ln -f railsrc           ~/.railsrc
ln -f vimrc             ~/.vimrc
if [ "`uname`"x -eq "Darwin"x  ]; then
  mkdir -p ~/Library/KeyBindings
  ln -f DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
fi

# TODO: Need more permission changes?
chmod go-rwx .*_history
