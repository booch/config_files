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
ln -sf ackrc             ~/.ackrc

ln -sf bash_aliases      ~/.bash_aliases
ln -sf bash_logout       ~/.bash_logout
ln -sf bash_profile      ~/.bash_profile
ln -sf bashrc            ~/.bashrc
ln -sf profile           ~/.profile

mkdir -p ~/.bundle
ln -sf bundle/config     ~/.bundle/config
ln -sf gemrc             ~/.gemrc
ln -sf irbrc             ~/.irbrc
ln -sf aprc              ~/.aprc
ln -sf railsrc           ~/.railsrc

ln -sf gitconfig         ~/.gitconfig
ln -sf gitignore         ~/.gitignore

ln -sf inputrc           ~/.inputrc

mkdir -p ~/.mc
ln -sf mc/ini            ~/.mc/ini

ln -sf nanorc            ~/.nanorc
mkdir -p ~/.nano
ln -sf nano/css.nanorc   ~/.nano/css.nanorc
ln -sf nano/php.nanorc   ~/.nano/php.nanorc
ln -sf nano/xml.nanorc   ~/.nano/xml.nanorc

ln -sf vimrc             ~/.vimrc
mkdir -p ~/.vim
mkdir -p ~/.vim/backup  # Make sure there's a global backup directory for vim.
ln -sf vim/packages.vim  ~/.vim/packages.vim
ln -sf vim/abbrev.vim    ~/.vim/abbrev.vim
ln -sf vim/keymaps.vim   ~/.vim/keymaps.vim
if [ ! -d vim/bundle/vundle ]; then
  git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
fi

ln -sf psqlrc            ~/.psqlrc

if [ "`uname`"x = "Darwin"x  ]; then
  mkdir -p ~/Library/KeyBindings
  ln -f DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
fi

# TODO: Need more permission changes?
chmod go-rwx ~/.*_history
