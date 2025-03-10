# TODO

## Top Priority

- Commit current changes
- Encrypted files
    - Use git-encrypt
    - Make sure password is well backed up
    - Personal git settings
    - NOT .ssh
        - That needs to be backed up elsewhere
- ZSH errors
    - Prompt
    - Startup
        - `compinit:527: no such file or directory: /opt/homebrew/share/zsh/site-functions/_docker_compose`
        - The file points at `/opt/homebrew/Caskroom/docker/4.22.1,118664/Docker.app/Contents/Resources/etc/docker-compose.zsh-completion`
            - But that file doesn't exist
                - Only `docker.zsh-completion` exists
                - This is because I'm no longer installing docker-desktop
- Enable [iTerm console integration](https://iterm2.com/documentation-shell-integration.html)
- Fix VS Code brokenness
    - Ruby LSP is frequently broken
        - VS Code seems to be trying to use Solargraph instead of Ruby LSP
            - I was using Ruby LSP, and it was working; what changed?
        - Seems to be due to default Ruby versions
            - Deleted ~/.ruby-version
            - TODO: Add .tool-versions to config_files
    - Solargraph frequently crashes
        - I didn't even know I was still running this
    - RuboCop is crashing on Style/WordArray
- Hook in spelling/dictionary.txt to the MacOS spelling dictionary (~/Library/Spelling/LocalDictionary)

## VS Code

- COMMIT: Configure VS Code to highlight some more things:
    - QUESTION: (blue)
    - ANSWER: (green)
    - PROBLEM: (orange red)
    - SOLUTION: (green)
    - NOTE: (dark magenta)
    - CMB (???)
    - BUG: (???)
    - BUGFIX: (???)
    - DEBUG: (???)
    - It already highlights `TODO:` and `FIXME:`.
    - See https://marketplace.visualstudio.com/items?itemName=wayou.vscode-todo-highlight
    - Works in Markdown, despite it not being listed
- Learn to use VS Code "Hey Code"
- Learn to use Cursorless in VS Code
    - Requires setting up Talon
- Add keybindings to VS Code
    - `Git: Stage Changes`
        - Adds the whole file
        - Is there 1 for the current hunk?
            - `Git: Stage Block`
            - `Git: Stage Selection`
            - `Git: Stage Selected Ranges`
    - `GitHub Copilot: Generate this`
    - `GitHub Copilot: Apply suggestion`
    - `GitHub Copilot: Open completions panel`
        - Ctrl + Enter
    - `GitHub Copilot: Accept panel suggestion`
    - Uppercase/lowercase/capitalize
    - Collapse/show current section
    - Open settings.json
    - Go to enclosing/matching bracket (like % in Vim)
        - I'm thinking `Option + Shift + 5` (Option + %)
            - Maybe use one of the bracket keys
        - Copilot suggests `Ctrl + Shift + \`
            - Does not appear to do anything out of the box
    - Go to next/previous error
- Learn VS Code keybindings
    - `Cmd + Shift + E` to show Explorer view
    - `Cmd + Shift + V` to show Preview view (I have this overridden by my paste manager)
    - `Cmd + Shift + F` to show Search view
    - `Cmd + Shift + H` to show Replace view
    - `Cmd + Shift + M` to toggle Problems view
    - `Ctrl + Shift + G` to show Source Control view
    - `Cmd + Shift + X` to show Extensions view
    - `Cmd + Shift + D` to show Debug view
    - `Cmd + Shift + R` to show Refactoring view (does not work for me)
    - `Cmd + Shift + T` to show Terminal view (does not work for me)
    - `Cmd + Shift + U` to toggle Output view
    - `Cmd + Shift + I` to toggle Copilot
    - `Cmd + Shift + K` to cut the entire line
    - `Cmd + Shift + L` to show Language mode view
    - `Cmd + Shift + N` to open a new window/workspace
    - `Cmd + Shift + O` to open Symbol search
    - `Cmd + Shift + S` to show Save File dialog
    - `Cmd + Shift + W` to show Close Workspace (possibly prompting to save it)
    - `Cmd + Shift + Z` to Redo
    - `Cmd + Shift + Y` to toggle Debug Console
    - `Cmd + Shift + 1` through `9` - open nth editor group
- VS Code "fixes"
    - Make the "collapse" symbols a little *less* visible
    - View / Appearance / Editor Actions Position / Title Bar


## iTerm

* Saving a setting re-writes "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    * It won't honor a symlink in that location
    * Will need to write a pre-commit and post-pull hook, I think
* Use correct TERM if possible
    * See terminfo in /opt/homebrew/Cellar/ncurses/6.4/share/terminfo
        * Has iTerm2.app, iterm2-direct
        * Has Apple_Terminal
        * Has tmux-256color and tmux-direct
        * Should have `RGB` and/or `Tc`
            * https://github.com/tmux/tmux/wiki/FAQ#how-do-i-use-rgb-colour

* Adding -X to less is causing DEL to stop working after we exit less
    * Or maybe it isn't?

* Include private settings using git-encrypt.
    * git/local


* Add Firefox stuff:
    * userChrome.css
    * user.js

* Create a [pgcli/config](https://www.pgcli.com/config) file.
    * Ignore `pgcli/log`

## Installer

* Fix error on install:
    ln: /Users/booch/.atom/packages/touchbar-utility/lib/configuration.js: No such file or directory:
* Make sure we're not creating circular soft links, like `zshrc.d/zshrc.d`.
    * And Work/Work
* Add script/alias to push/pull new versions of this repo.



## Shell

* Move /usr/local before /usr in $PATH.
* Create an alias for `diff` to use `git diff`
    * `alias diff='git diff --no-index --color=always --no-ext-diff'`
    * See https://sgeb.io/posts/2016/11/til-git-diff-anywhere/
    * The `--no-index` is the important bit
        * It tells git not to compare to the index (staged files)
* Break `bashrc` up like we're breaking up `profile.d`
* Determine what really belongs in `bashrc` and what belongs in `profile`
* Make a command to return ANSI color codes, instead of VARIABLES
    * echo "$(color green)Hello, $(color green on black)World!$(color none)"
    * Also allow for `prompt`, which will surround it with `'\['` and `'\]'`
* Move setting of prompt to its own file (in `profile.d` or `bashrc.d`)
* Add to `key_bindings.sh`
    * Attempt to reach parity with [ZSH For Humans](https://github.com/romkatv/zsh4humans)


## RuboCop

* Use 4-space indentation
* Change `Style` to `Layout` as appropriate
    * Version 0.49 moved a lot of rules into a new `Layout` section
* Review new rules (added since about 0.37) to see how I want them configured


## Git

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


## Vim

- Learn Vim better
    - `%` = jump to matching bracket

- Install more plugins (via Vundle):
    * tpope/vim-commentary - comment/uncomment blocks of code
    * tpope/vim-fugitive - Git
    * tpope/vim-rails - Rails
    * tpope/vim-haml - HAML
    * tpope/vim-sensible - Defaults everyone can agree on

## Karabiner

* Limit to built-in laptop keyboard(s):
    * Fn to Control mappings
    * Right Option to Right Control
* Finder fixes
    * Enter to open (Command+O)
        * https://github.com/tekezo/Files/blob/master/Karabiner/private.finder_return_to_open/private.xml
* Windows equivalents
    * F5 to Command+R (for refreshing pages) (and shifted variant) (and Command+F5)
    * Alt+F4 to Command+Q (and Command+F4)
* Restore settings from old Karabiner XML
    * Only for Apple Keyboard with Numeric Keypad (device ID 0x024f)
        * Shift+Fn to Paste (Command+V)
        * Control+Fn to Copy (Command+C)
        * Shift+ForwardDelete to Cut (Command+X)
        * Fn To F19 (terminal apps only) (to work as Insert)
    * Same thing for PC keyboards
        * Use `PC Insert` instead of `Fn`
    * Hot Keys (runs a command)
        * Command+Shift+Comma opens System Preferences
            * /Applications/System Preferences.app
            * Because Command+Comma is the standard keystroke to open Preferences in applications
        * Lock screen (maybe Command+Shift+L)
            * /usr/bin/pmset displaysleepnow
            * /usr/bin/osascript -e 'tell application "System Events" to sleep'
    * Others
        * Control+PageDown (and PageUp) to Cycle Through Tabs (Control+Tab)
        * Control+Return To Send Email (Command+Shift+D) (Apple Mail app only)
* Decide what to do with a Hyper key
    * Emacs?
    * Vim mappings?
    * App launching?
    * System actions?
        * Change Desktops (Spaces)
        * Change window sizes/locations (remap Magnet key-bindings)
* Space bar as modifier
    * Hyper?
    * Control?
    * Shift?
    * HJKL and WASD to cursor keys?
* Tab key as modifier
    * Super?
* Esc key as modifier
    * Hyper?
* Chording?
    * See some examples at https://pqrs.org/osx/karabiner/list.html.en
        * Simultaneous Key Presses
            * Simultaneous arrow keys presses to Home/End/PageUp/PageDown
            * Simultaneous Key Presses [F+HJKL] to Left/Down/Up/Right
        * [ASETNIOP](http://asetniop.com/)
        * [Engelbart](https://github.com/gabrielelana/engelbart/)
* Return as Control modifier?
* Mouse keys
    * Example at https://github.com/tekezo/Files/blob/master/Karabiner/private.mouse_keys_mode_v2_option/private.xml
    * Example at https://github.com/tekezo/Files/blob/master/Karabiner/private.mouse_keys_mode_v2_ijkl/private.xml
* Command+\ to mirror Command+Tab
    * Example at https://github.com/tekezo/Files/blob/master/Karabiner/private.command_backslash_to_command_tab/private.xml
* Fix shortcuts to beginning/end of file
    * Example at https://github.com/tekezo/Files/blob/master/Karabiner/private.control_home_end_to_beginning_end_of_file/private.xml
* Ensure I use the correct Shift keys
    * See http://stevelosh.com/blog/2012/10/a-modern-space-cadet/#better-shifting
    * Also try the Shift to Parentheses that he suggests
        * Or maybe Shift+Space for open/close parentheses
* Sticky modifiers
* Alternate key layouts
    * Dvorak ([Programmer Dvorak](http://www.kaufmann.no/roland/dvorak/) specifically)
    * [Colemak](https://colemak.com/)
    * [Norman](https://normanlayout.info/)
    * [Capewell](http://www.michaelcapewell.com/projects/keyboard/layout_capewell.htm)
    * [QGMLWY](http://mkweb.bcgsc.ca/carpalx/?full_optimization)
* Use my chording keyers
    * [Twiddler 3](http://twiddler.tekgear.com/)
    * [In10did DecaTxt](http://in10did.com/decatxt.html)
* Build a chording keyer
    * Use an [Adafruit Feather 32u4 Bluefruit LE](https://www.adafruit.com/product/3379) controller
    * Use Arduino code based on [SpiffChorder code](https://github.com/clc/chorder/blob/master/FeatherChorder/FeatherChorder.ino)
    * See if we can get 2 buttons on the index and middle fingers
        * Or at least 2 different "on" positions
        * This would give 30-60 combinations (not including the thumb)
    * See if we can get 4 buttons on the thumb
        * Or something like a joystick with 4 positions
        * Or 2 rocker switches with 2 "on" positions each
    * See if we can get the thumb buttons to be toggles
        * They'll remain in "on" position until we press them a 2nd time
        * It should be easy to feel them to determine what state they're in
    * Ideal modifiers:
        * letters (no modifiers)
        * shift
        * number/punctuation (plus shifted variants)
        * control
        * command (and movements and actions)


## Atom

[I don't really use Atom any more, so these can probably be deleted.]

* Change key-binding for Edit / Bookmark / View All
    * The default `Control+F2` conflicts with the `Move focus to the menu bar` global shortcut
* Remove key-bindings for Ctrl+Tab
    * Can now do that by unchecking **Enable MRU Tab Switching** in `Tabs` package
* Restore Cmd+Shift+T back to reopening the most-recently closed tab
    * Terminal-plus is overriding it
* If in Terminal-plus, have Cmd+W close the terminal, instead of the current tab
* Fix YAML Semanticolor settings
    * Only colorize left side of key/value pairs
        * Leave everything else normal color
* Default Markdown to 4-space indentation
* Default YAML to 4-space indentation
* Make completion/expansion less aggressive
    * Like when I type `tab` and hit *Tab*, it expands to `table`, then to a Markdown table
