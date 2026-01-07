-- Color theme configuration
-- Light themes with 24-bit colors

return {
  -- Boochtek - Custom theme combining the best qualities
  -- Combines: OneDarkPro colorfulness + Bluloco backgrounds + Strong UI definition
  {
    'boochtek-custom-theme',
    dir = vim.fn.stdpath('config'),
    lazy = false,
    priority = 1001, -- Load before other themes
    config = function()
      vim.cmd('colorscheme boochtek')
    end,
  },

  -- OneDarkPro - Very colorful, customizable
  {
    'olimorris/onedarkpro.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('onedarkpro').setup {
        colors = {
          -- Use Bluloco-inspired background for better contrast
          cursorline = '#E6F3FF',
        },
        highlights = {
          -- Enhance modeline visibility (more defined)
          StatusLine = { bg = '#0099FF', fg = '#ffffff', style = 'bold' },
          StatusLineNC = { bg = '#D0D0D0', fg = '#505050' },
          -- Enhance current line visibility
          CursorLine = { bg = '#E6F3FF' },
          CursorLineNr = { fg = '#0099FF', bg = '#E6F3FF', style = 'bold' },
          -- Make line numbers more visible
          LineNr = { fg = '#8090A0' },
        },
        options = {
          cursorline = true,
          transparency = false,
          terminal_colors = true,
          highlight_inactive_windows = true,
        },
      }
      -- To activate: uncomment the line below
      -- vim.cmd('colorscheme onelight')
    end,
  },

  -- PaperColor - Clean and readable
  {
    'NLKNguyen/papercolor-theme',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.PaperColor_Theme_Options = {
        theme = {
          default = {
            transparent_background = 0,
            allow_bold = 1,
            allow_italic = 1,
          },
        },
      }
      -- vim.cmd('colorscheme PaperColor')
      -- vim.opt.background = 'light'
    end,
  },

  -- Humanoid - Balanced and easy on the eyes
  {
    'humanoid-colors/vim-humanoid-colorscheme',
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd('colorscheme humanoid')
      -- vim.opt.background = 'light'
    end,
  },

  -- Bluloco - Great background colors
  {
    'uloco/bluloco.nvim',
    lazy = false,
    priority = 1000,
    dependencies = { 'rktjmp/lush.nvim' },
    config = function()
      require('bluloco').setup {
        style = 'light', -- "auto" | "dark" | "light"
        transparent = false,
        italics = true,
        terminal = vim.o.termguicolors,
      }
      vim.cmd('colorscheme bluloco-light')

      -- Enhanced customizations after theme loads
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'bluloco-light',
        callback = function()
          -- Make current line more visible
          vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#E6F3FF' })
          vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#0099FF', bg = '#E6F3FF', bold = true })

          -- Make status line more visible
          vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#ffffff', bg = '#0099FF', bold = true })
          vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#505050', bg = '#D0D0D0' })
        end,
      })
    end,
  },

  -- Keep Tomorrow theme as fallback
  {
    'chriskempson/vim-tomorrow-theme',
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd('colorscheme Tomorrow')
      -- vim.opt.background = 'light'
    end,
  },
}

-- NOTE: To activate a different theme, uncomment the vim.cmd('colorscheme ...') line in the config
-- Current active theme: boochtek (custom theme combining your favorite qualities)
--
-- Available light themes:
-- - boochtek (Custom) - Combines OneDarkPro colorfulness + Bluloco backgrounds + Strong UI
-- - onelight (OneDarkPro) - Most colorful, enhanced modeline/cursorline
-- - PaperColor (set background to light) - Clean and readable
-- - humanoid (set background to light) - Balanced
-- - bluloco-light (Bluloco) - Great backgrounds
-- - Tomorrow (fallback)
--
-- Quick switch command: :colorscheme <theme-name>
