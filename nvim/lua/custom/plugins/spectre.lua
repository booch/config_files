return {
  {
    'nvim-pack/nvim-spectre',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>sr',
        function()
          require('spectre').toggle()
        end,
        desc = '[S]earch and [R]eplace (Spectre)',
      },
      {
        '<leader>sw',
        function()
          require('spectre').open_visual { select_word = true }
        end,
        desc = '[S]earch current [W]ord (Spectre)',
      },
      {
        '<leader>sw',
        function()
          require('spectre').open_visual()
        end,
        mode = 'v',
        desc = '[S]earch selection (Spectre)',
      },
      {
        '<leader>sp',
        function()
          require('spectre').open_file_search { select_word = true }
        end,
        desc = '[S]earch in current file (S[p]ectre)',
      },
    },
  },
}
