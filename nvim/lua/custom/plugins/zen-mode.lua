return {
  {
    'folke/zen-mode.nvim',
    dependencies = { 'folke/twilight.nvim' },
    opts = {
      window = {
        width = 120,
        options = {
          signcolumn = 'no',
          number = false,
          relativenumber = false,
          cursorline = false,
          cursorcolumn = false,
          foldcolumn = '0',
          list = false,
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
        tmux = { enabled = false },
      },
    },
    keys = {
      { '<leader>zz', '<cmd>ZenMode<cr>', desc = 'Toggle Zen Mode' },
    },
  },
  {
    'folke/twilight.nvim',
    opts = {
      dimming = {
        alpha = 0.25,
      },
      context = 10,
    },
  },
}
