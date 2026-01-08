-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Shift+cursor keys to select text (enter visual mode if not already in it)
-- Neovim receives Shift+cursor keys correctly, we just need to map them properly
-- The trick is that Neovim defaults may interfere, so we need to be explicit

-- First, ensure we're not in select mode behaviors that might interfere
vim.o.selectmode = ""  -- Don't use select mode
vim.o.keymodel = ""    -- Don't use special shift behaviors

-- Normal mode: enter visual mode and move
vim.keymap.set('n', '<S-Up>', 'v<Up>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Down>', 'v<Down>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Left>', 'v<Left>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Right>', 'v<Right>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Home>', 'v^', { noremap = true, silent = true })
vim.keymap.set('n', '<S-End>', 'v$', { noremap = true, silent = true })

-- Visual mode: extend selection with Shift+cursor
vim.keymap.set('v', '<S-Up>', '<Up>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Down>', '<Down>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Left>', '<Left>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Right>', '<Right>', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Home>', '^', { noremap = true, silent = true })
vim.keymap.set('v', '<S-End>', '$', { noremap = true, silent = true })

-- Visual mode: cancel selection with unshifted cursor keys (like most editors)
vim.keymap.set('v', '<Up>', '<Esc><Up>', { noremap = true, silent = true })
vim.keymap.set('v', '<Down>', '<Esc><Down>', { noremap = true, silent = true })
vim.keymap.set('v', '<Left>', '<Esc><Left>', { noremap = true, silent = true })
vim.keymap.set('v', '<Right>', '<Esc><Right>', { noremap = true, silent = true })
vim.keymap.set('v', '<Home>', '<Esc><Home>', { noremap = true, silent = true })
vim.keymap.set('v', '<End>', '<Esc><End>', { noremap = true, silent = true })
vim.keymap.set('v', '<PageUp>', '<Esc><PageUp>', { noremap = true, silent = true })
vim.keymap.set('v', '<PageDown>', '<Esc><PageDown>', { noremap = true, silent = true })

-- Insert mode: exit insert, enter visual, move
vim.keymap.set('i', '<S-Up>', '<Esc>v<Up>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Down>', '<Esc>v<Down>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Left>', '<Esc>v<Left>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Right>', '<Esc>v<Right>', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Home>', '<Esc>v^', { noremap = true, silent = true })
vim.keymap.set('i', '<S-End>', '<Esc>v$', { noremap = true, silent = true })

-- vim: ts=2 sts=2 sw=2 et
