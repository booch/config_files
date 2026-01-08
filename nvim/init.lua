--[[

=====================================================================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- My Pre-Kickstart Neovim config
-- Load vim config AFTER plugins are loaded
vim.opt.runtimepath:prepend '~/.vim'
vim.opt.packpath = vim.o.runtimepath
vim.g.skip_colors_vim = nil
vim.cmd 'source ~/.vimrc'

-- Override vimrc settings that interfere with Neovim shift+cursor behavior
-- The vimrc sets selectmode=mouse,key which we need to override
vim.o.selectmode = ""  -- Disable select mode for keys
vim.o.keymodel = ""    -- Disable special shift behaviors

-- Re-apply shift+cursor mappings after vimrc loads (since vimrc may have overridden them)
-- Normal mode: enter visual mode and move
vim.keymap.set('n', '<S-Up>', 'v<Up>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Down>', 'v<Down>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Left>', 'v<Left>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Right>', 'v<Right>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Home>', 'v^', { noremap = true, silent = true })
vim.keymap.set('n', '<S-End>', 'v$', { noremap = true, silent = true })

-- Visual mode: extend selection
vim.keymap.set('v', '<S-Up>', '<Up>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Down>', '<Down>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Left>', '<Left>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Right>', '<Right>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Home>', '^', { noremap = true, silent = true })
vim.keymap.set('v', '<S-End>', '$', { noremap = true, silent = true })

-- Insert mode: exit insert, enter visual, move
vim.keymap.set('i', '<S-Up>', '<Esc>v<Up>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Down>', '<Esc>v<Down>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Left>', '<Esc>v<Left>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Right>', '<Esc>v<Right>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Home>', '<Esc>v^', { noremap = true, silent = true })
vim.keymap.set('i', '<S-End>', '<Esc>v$', { noremap = true, silent = true })

-- Enable markdown syntax highlighting (fallback if treesitter doesn't work)
vim.g.markdown_fenced_languages = { 'bash', 'sh', 'shell=sh', 'ruby', 'python', 'javascript', 'js=javascript', 'lua', 'vim' }

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
