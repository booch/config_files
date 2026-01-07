-- Git integration (Neovim-specific only, others loaded from vimrc)
return {
  -- Gitsigns - already included in kickstart for inline git signs
  -- vim-fugitive is already loaded from ~/.vimrc and works in both Vim and Neovim

  -- diffview.nvim - Enhanced diff viewing and conflict resolution
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Open Git Diffview' },
      { '<leader>gh', '<cmd>DiffviewFileHistory<CR>', desc = 'Open Git File History' },
      { '<leader>gc', '<cmd>DiffviewClose<CR>', desc = 'Close Git Diffview' },
    },
    opts = {
      enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
    },
  },
}
