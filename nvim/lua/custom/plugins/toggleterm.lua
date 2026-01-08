return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = 'float',
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = 'curved',
        winblend = 0,
      },
    },
    keys = {
      { [[<c-\>]], desc = 'Toggle terminal' },
      {
        '<leader>tf',
        '<cmd>ToggleTerm direction=float<cr>',
        desc = '[T]erminal [F]loat',
      },
      {
        '<leader>th',
        '<cmd>ToggleTerm direction=horizontal<cr>',
        desc = '[T]erminal [H]orizontal',
      },
      {
        '<leader>tv',
        '<cmd>ToggleTerm direction=vertical<cr>',
        desc = '[T]erminal [V]ertical',
      },
    },
  },
}
