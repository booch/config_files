---
description: Update Homebrew and all installed packages, with a summary of changes
---

Update Homebrew and all installed packages. Provide a summary of what was updated.

## Steps

1. Run `brew update` to update Homebrew itself and fetch the latest formulae/cask definitions.

2. Run `brew outdated` to capture the list of outdated packages BEFORE upgrading. Save this list — you'll need it for the summary.

3. **Before running `brew upgrade`**, warn the user with this exact message (use yellow/amber ANSI color and bold):

   **\033[1;33m⚠️  HEADS UP: The upgrade may trigger a Touch ID or sudo password prompt. Some cask upgrades (e.g. git-credential-manager) require elevated privileges. Keep an eye out for a system dialog.\033[0m**

   Wait for the user to acknowledge before proceeding.

4. Run `brew upgrade` to upgrade all outdated formulae and casks. Use a 10-minute timeout.

5. Run `brew cleanup` to remove old versions.

6. Restart any daemons/services that the upgrade output recommends restarting, using `brew services restart <service>`.

7. Produce a summary:
   - List all packages that were upgraded, showing old version -> new version.
   - For these important/daily-use packages, provide a TLDR of notable changes (search the web for release notes if needed): git, jj, bash, zsh, openssl, curl, jq, ripgrep, fd, fzf, tmux, neovim, gh, opencode, claude-code (claude), httpie, eza, delta, direnv, mise, ghostty, iterm.
   - For any OTHER package that had a MAJOR version bump (e.g., 2.x -> 3.x), also provide a TLDR.
   - Skip TLDRs for packages with only patch-level bumps (e.g., 2.3.4 -> 2.3.5) or if there are no notable features. Omit them from the TLDR section entirely — just list them in the "all other upgrades" table.

8. At the end, report any errors or warnings from the upgrade process.
