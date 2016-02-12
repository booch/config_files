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


