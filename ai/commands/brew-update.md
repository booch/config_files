---
description: Update Homebrew and all installed packages, with a summary of changes
---

Update Homebrew and all installed packages. Provide a summary of what was updated.

## Steps

1. **Check for concurrent brew processes.** Before anything else, check for stale lock files:
   ```
   find ~/Library/Caches/Homebrew/downloads/ -name "*.incomplete"
   ```
   - If `.incomplete` files exist, check whether a `brew upgrade` process is actually running (`pgrep -f 'brew upgrade'`).
   - If a process IS running: **abort** and tell the user another upgrade is in progress.
   - If NO process is running: the locks are stale. Clean them up with `find ~/Library/Caches/Homebrew/downloads/ -name "*.incomplete" -delete` and continue.

2. Run `brew update` to update Homebrew itself and fetch the latest formulae/cask definitions.

3. Run `brew outdated --verbose` to capture the list of outdated packages BEFORE upgrading. Save this list — you'll need it for the summary.

4. **Before running `brew upgrade`**, warn the user:

   **HEADS UP: The upgrade may trigger a Touch ID or sudo password prompt. Some cask upgrades require elevated privileges.**

5. Run `brew upgrade` to upgrade all outdated formulae and casks. Use a 10-minute timeout.

6. Run `brew cleanup` to remove old versions.

7. Run `brew services list` and check if any upgraded packages have running services that should be restarted. Use `brew services restart <service>` as needed.

8. Produce a summary:
   - List all packages that were upgraded, showing old version -> new version.
   - For these important/daily-use packages, provide a TLDR of notable changes (search the web for release notes if needed):
      - git, jj, bash, zsh, openssl, curl, jq, ripgrep, fd, fzf, tmux, neovim, gh, opencode, claude-code (claude), httpie, eza, delta, direnv, mise, ghostty, iterm
   - For any OTHER package that had a MAJOR version bump (eg, 2.x -> 3.x), also provide a TLDR.
      - If the version number starts with 0, provide a TLDR if the second number increases.
   - Skip TLDRs for packages with only patch-level bumps (eg, 2.3.4 -> 2.3.5) or if there are no notable features. Omit them from the TLDR — just list them in the "all other upgrades" table.
   - No need to show freed disk space.

9. Report any errors or warnings from the upgrade process.
