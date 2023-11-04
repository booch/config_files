# My Config Files

These are all my config files for GNU/Linux and MacOS systems.

To use this, fork the repo, then change `REPO_OWNER` in the script below to
your GitHub user name. Then run the commands from the shell.

~~~ shell
REPO_OWNER='booch'
mv "$HOME/.config" "$HOME/.config-BACKUP-$(date +'%Y%m%d')"
git clone "git@github.com:${REPO_OWNER}/config_files.git" "$HOME/.config"
cd "$HOME/.config"
./install.sh
~~~
