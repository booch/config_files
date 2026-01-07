-- Session management - automatically save and restore editing sessions
return {
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      log_level = 'error',
      auto_session_enable_last_session = false,
      auto_session_root_dir = vim.fn.stdpath 'data' .. '/sessions/',
      auto_session_enabled = true,
      auto_save_enabled = true,
      auto_restore_enabled = true,
      auto_session_suppress_dirs = { '~/', '~/Downloads', '/' },
      auto_session_use_git_branch = false,
    },
    keys = {
      { '<leader>qs', '<cmd>SessionSave<CR>', desc = 'Save Session' },
      { '<leader>qr', '<cmd>SessionRestore<CR>', desc = 'Restore Session' },
      { '<leader>qd', '<cmd>SessionDelete<CR>', desc = 'Delete Session' },
    },
  },
}
