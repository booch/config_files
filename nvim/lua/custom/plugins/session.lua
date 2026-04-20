-- Session management - automatically save and restore editing sessions
return {
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      log_level = 'error',
      auto_restore_last_session = false,
      root_dir = vim.fn.stdpath 'data' .. '/sessions/',
      enabled = true,
      auto_save = true,
      auto_restore = true,
      suppressed_dirs = { '~/', '~/Downloads', '/' },
      git_use_branch_name = false,
    },
    keys = {
      { '<leader>qs', '<cmd>SessionSave<CR>', desc = 'Save Session' },
      { '<leader>qr', '<cmd>SessionRestore<CR>', desc = 'Restore Session' },
      { '<leader>qd', '<cmd>SessionDelete<CR>', desc = 'Delete Session' },
    },
  },
}
