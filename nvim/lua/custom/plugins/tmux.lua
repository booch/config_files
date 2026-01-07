-- Tmux integration for seamless pane switching between vim and tmux
return {
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate to left pane' },
      { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate to down pane' },
      { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate to up pane' },
      { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate to right pane' },
      { '<C-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate to previous pane' },
    },
  },
}
