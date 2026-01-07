-- Force treesitter to install and compile parsers on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      local parser_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"
      -- Check if parser directory is empty
      local has_parsers = vim.fn.isdirectory(parser_dir) == 1 and #vim.fn.readdir(parser_dir) > 0
      if not has_parsers then
        print("Installing treesitter parsers...")
        vim.cmd("TSUpdate")
      end
    end, 100)
  end,
})

return {}
