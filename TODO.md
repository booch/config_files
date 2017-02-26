Git
===

* Use diff-so-fancy
    * Take a look at the below settings I snagged from somewhere.
        ~~~
        [pager]
            diff = diff-so-fancy | less --tabs=4 -RFX --pattern '^(Date|added|deleted|modified): '
        [color "diff"]
            meta = yellow bold
            commit = green bold
            frag = magenta bold
            old = red bold
            new = green bold
            whitespace = red reverse
        [color "diff-highlight"]
            oldNormal = red bold
            oldHighlight = "red bold 52"
            newNormal = "green bold"
            newHighlight = "green bold 22"
        [color "branch"]
            current = yellow reverse
            local = yellow
            remote = green
        [color "status"]
            added = yellow
            changed = green
            untracked = cyan
        [alias]
            patch = !git --no-pager diff --no-color
        ~~~


Vim
===

Install more plugins (via Vundle):

* tpope/vim-commentary - comment/uncomment blocks of code
* tpope/vim-fugitive - Git
* tpope/vim-rails - Rails
* tpope/vim-haml - HAML
* tpope/vim-sensible - Defaults everyone can agree on



Mac Config
==========

Keymapping
----------

* CapsLock -> Control
* Right Option -> Control (laptop only)
* Keyboard preferences -> Shortcuts
  * Disable most of them
    * Especially the Ctrl+Shift cursor keys, which override Sublime block selection mode.
* Set some global app key-bindings (can also set them per app) (preferences calls tab \U21E5, but it should probably be \U0011):
	defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Select Next Tab"      '^\U21E5'
	defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Select Previous Tab"  '^~\U21E5'
	defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Next Tab"             '^\U21E5'
	defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Previous Tab"         '^~\U21E5'
