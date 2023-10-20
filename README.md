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

## TODO

- Include private settings using git-encrypt.
- Fix error on install:
    ln: /Users/booch/.atom/packages/touchbar-utility/lib/configuration.js: No such file or directory:
- Hook in spelling/dictionary.txt to the MacOS spelling dictionary (~/Library/Spelling/LocalDictionary)

Move /usr/local before /usr in $PATH.
Consider pulling in someone else's dotfiles framework.
    Would ease the burden of updating the install script.
Add script/alias to push/pull new versions.
Add Firefox stuff:
    userChrome.css
    user.js
