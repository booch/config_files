return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      -- WORKAROUND: tree-sitter-cli 0.26.3 has a bug with lock files that causes parser
      -- compilation to fail with panic errors. To work around this:
      -- 1. prefer_git = false: Download pre-built tarballs instead of cloning git repos
      -- 2. compilers: Use system C compiler (clang/gcc/cc) directly instead of tree-sitter CLI
      -- This allows parsers to compile to ~/.local/share/nvim/lazy/nvim-treesitter/parser/*.so
      -- Once tree-sitter-cli is fixed (version > 0.26.3), these can be removed.
      require('nvim-treesitter.install').prefer_git = false
      require('nvim-treesitter.install').compilers = { 'clang', 'gcc', 'cc' }

      -- NOTE: In older nvim-treesitter, this was 'nvim-treesitter.configs'
      -- The module path changed in newer versions
      local configs_ok, configs = pcall(require, 'nvim-treesitter.configs')
      if not configs_ok then
        -- Try alternate module path for newer versions
        configs_ok, configs = pcall(require, 'nvim-treesitter')
      end

      if configs_ok and configs.setup then
        configs.setup {
          ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
          auto_install = true,
          sync_install = false,
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = { 'ruby' },
          },
          indent = { enable = true, disable = { 'ruby' } },
        }
      end
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}
-- vim: ts=2 sts=2 sw=2 et
