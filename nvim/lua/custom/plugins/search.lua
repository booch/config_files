-- Search plugins (Neovim-specific only, others loaded from vimrc)
-- Telescope (already in kickstart) has live_grep - use <space>sg
-- ack.vim is already loaded from ~/.vimrc and works in both Vim and Neovim

-- Configure ripgrep for ack if available
if vim.fn.executable('rg') == 1 then
  vim.g.ackprg = 'rg --vimgrep --smart-case'
end

return {}
