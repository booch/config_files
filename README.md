# My Config Files

These are all my config files for GNU/Linux and MacOS systems.

To use this, fork the repo, then change `REPO_OWNER` in the script below to
your GitHub user name. Then run the commands from the shell.

~~~ shell
REPO_OWNER='booch'
mv "$HOME/.config" "$HOME/.config-BACKUP-$(date +'%Y%m%d')"
git clone "git@github.com:${REPO_OWNER}/config_files.git" "$HOME/.config" \
    || git clone "https://github.com/${REPO_OWNER}/config_files.git" "$HOME/.config" \
        && printf 'WARNING: Cloned with HTTPS, change to SSH if you want to push changes.'
cd "$HOME/.config"
./install.sh
~~~
