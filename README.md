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

If you don't have SSH set up yet when you pull the repo, you probably won't be able to push to the repository. Once you've gotten SSH set up (and the public key added to GitHub), you'll need to change the `origin` remote to use SSH instead of HTTPS.

~~~ shell
git remote set-url origin "git@github.com:${REPO_OWNER}/config_files.git"
~~~

## install.sh

The install script creates symlinks so tools can find their config files.
It is idempotent — run it after every `git pull` or config change.
It can be run from any directory:

~~~ shell
~/.config/install.sh
~~~

On first run, if `git/local` doesn't exist, the script writes your git
identity there. It derives your name from your user account, your email
from the one that name has committed with most in this repo, and your
GitHub username from this repo's `origin`; it prompts only for what it
can't derive. That file is gitignored, so your git identity stays on
your machine and is never committed.

For tools that insist on a dot-folder in your home directory (such as
`~/.claude` or `~/.homebrew`), the script moves its contents into this
repo and links the dot-folder back here. Those links are relative
(`~/.claude -> .config/claude`), so they keep working on a Mac whose
home directory has a different name.
