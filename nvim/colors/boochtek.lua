-- Boochtek colorscheme
-- A custom light theme combining:
--   - Colorfulness of OneDarkPro
--   - Clean backgrounds from Bluloco
--   - Strong definition for UI elements

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.background = 'light'
vim.g.colors_name = 'boochtek'

-- Enable true colors
vim.o.termguicolors = true

-- Color palette (inspired by OneDarkPro light + Bluloco backgrounds)
local colors = {
  -- Base colors from Bluloco light backgrounds
  bg = '#F9F9F9',           -- Main background (Bluloco-inspired)
  bg_alt = '#EFEFEF',       -- Subtle gray for current line (Tomorrow-inspired)
  bg_ui = '#ECEFF4',        -- UI elements background

  -- Foreground colors
  fg = '#383A42',           -- Main text
  fg_dim = '#696C77',       -- Comments

  -- Colorful syntax (OneDarkPro-inspired)
  red = '#C03030',          -- Errors, deletion (darker, less orange)
  orange = '#DA8548',       -- Constants, numbers
  yellow = '#F0A83E',       -- Warnings, strings
  green = '#3D7D3C',        -- Strings, additions (darker from #4E9A4D)
  cyan = '#0184BC',         -- Methods, support
  blue = '#2F5CC0',         -- Functions, keywords (slightly darker from #3668D4)
  purple = '#A626A4',       -- Keywords, tags
  magenta = '#CA1243',      -- Special

  -- UI accent colors (less bright, more muted)
  ui_blue = '#5577A0',      -- Darker muted blue-gray for UI elements
  ui_blue_light = '#DADADA', -- Darker gray for current line (Tomorrow-like)
  ui_red_light = '#F5DADA',  -- Light red for insert mode current line
  ui_orange_light = '#FFE8D0', -- Light orange for visual mode current line
  ui_yellow_light = '#FFF4CC', -- Light yellow for visual mode selection
  ui_gray = '#D0D0D0',      -- Inactive elements
  ui_gray_dark = '#505050', -- Inactive text

  -- Additional colors
  line_number = '#8090A0',
  selection = '#D4E7FF',
  search = '#FFE792',
  diff_add = '#C5F5C5',
  diff_change = '#E6F3FF',
  diff_delete = '#FFD4D4',
}

-- Helper function to set highlights
local function hi(group, opts)
  local cmd = 'highlight ' .. group
  if opts.fg then cmd = cmd .. ' guifg=' .. opts.fg end
  if opts.bg then cmd = cmd .. ' guibg=' .. opts.bg end
  if opts.sp then cmd = cmd .. ' guisp=' .. opts.sp end
  if opts.style then cmd = cmd .. ' gui=' .. opts.style end
  if opts.link then cmd = 'highlight! link ' .. group .. ' ' .. opts.link end
  vim.cmd(cmd)
end

-- Editor UI
hi('Normal', { fg = colors.fg, bg = colors.bg })
hi('NormalFloat', { fg = colors.fg, bg = colors.bg_ui })
hi('Visual', { bg = colors.selection })
hi('VisualNOS', { link = 'Visual' })

-- Cursor and lines
hi('Cursor', { fg = colors.bg, bg = colors.fg })
hi('CursorLine', { bg = colors.ui_blue_light })
hi('CursorLineNr', { fg = colors.ui_blue, bg = colors.ui_blue_light, style = 'bold' })
hi('CursorColumn', { bg = colors.ui_blue_light })
hi('ColorColumn', { bg = colors.bg_ui })
hi('LineNr', { fg = colors.line_number })

-- Status line - Strong definition
hi('StatusLine', { fg = '#ffffff', bg = colors.ui_blue, style = 'bold' })
hi('StatusLineNC', { fg = colors.ui_gray_dark, bg = colors.ui_gray })

-- Lualine separator highlights (force white color)
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_a_normal_to_lualine_b_normal', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_b_normal_to_lualine_c_normal', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_a_insert_to_lualine_b_insert', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_b_insert_to_lualine_c_insert', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_a_visual_to_lualine_b_visual', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_b_visual_to_lualine_c_visual', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_a_command_to_lualine_b_command', { fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'lualine_transitional_lualine_b_command_to_lualine_c_command', { fg = '#ffffff' })

-- Ensure all statusline-related highlights use white text
hi('User1', { fg = '#ffffff', bg = colors.ui_blue })
hi('User2', { fg = '#ffffff', bg = colors.ui_blue })
hi('User3', { fg = '#ffffff', bg = colors.ui_blue })
hi('User4', { fg = '#ffffff', bg = colors.ui_blue })
hi('User5', { fg = '#ffffff', bg = colors.ui_blue })
hi('User6', { fg = '#ffffff', bg = colors.ui_blue })
hi('User7', { fg = '#ffffff', bg = colors.ui_blue })
hi('User8', { fg = '#ffffff', bg = colors.ui_blue })
hi('User9', { fg = '#ffffff', bg = colors.ui_blue })

-- Tab line
hi('TabLine', { fg = colors.fg_dim, bg = colors.bg_ui })
hi('TabLineFill', { bg = colors.bg_ui })
hi('TabLineSel', { fg = colors.fg, bg = colors.bg, style = 'bold' })

-- Search
hi('Search', { bg = colors.search })
hi('IncSearch', { fg = colors.bg, bg = colors.orange, style = 'bold' })

-- Messages
hi('ErrorMsg', { fg = colors.red, style = 'bold' })
hi('WarningMsg', { fg = colors.yellow, style = 'bold' })
hi('ModeMsg', { fg = colors.green, style = 'bold' })
hi('MoreMsg', { fg = colors.cyan, style = 'bold' })
hi('Question', { fg = colors.blue, style = 'bold' })

-- Splits and windows
hi('VertSplit', { fg = colors.ui_gray })
hi('WinSeparator', { fg = colors.ui_gray })

-- Diff
hi('DiffAdd', { bg = colors.diff_add })
hi('DiffChange', { bg = colors.diff_change })
hi('DiffDelete', { fg = colors.red, bg = colors.diff_delete })
hi('DiffText', { bg = colors.selection, style = 'bold' })

-- Folding
hi('Folded', { fg = colors.fg_dim, bg = colors.bg_ui })
hi('FoldColumn', { fg = colors.fg_dim, bg = colors.bg })

-- Popup menu
hi('Pmenu', { fg = colors.fg, bg = colors.bg_ui })
hi('PmenuSel', { fg = colors.bg, bg = colors.ui_blue, style = 'bold' })
hi('PmenuSbar', { bg = colors.bg_ui })
hi('PmenuThumb', { bg = colors.ui_blue })

-- Syntax - Colorful like OneDarkPro
hi('Comment', { fg = colors.fg_dim, style = 'italic' })
hi('String', { fg = colors.green })
hi('Number', { fg = colors.orange })
hi('Boolean', { fg = colors.orange })
hi('Constant', { fg = colors.orange })

hi('Identifier', { fg = colors.red })
hi('Function', { fg = colors.blue, style = 'bold' })

hi('Statement', { fg = colors.purple, style = 'bold' })
hi('Conditional', { fg = colors.purple, style = 'bold' })
hi('Repeat', { fg = colors.purple, style = 'bold' })
hi('Label', { fg = colors.purple })
hi('Operator', { fg = colors.cyan })
hi('Keyword', { fg = colors.purple, style = 'bold' })
hi('Exception', { fg = colors.purple })

hi('PreProc', { fg = colors.yellow })
hi('Include', { fg = colors.purple })
hi('Define', { fg = colors.purple })
hi('Macro', { fg = colors.magenta })
hi('PreCondit', { fg = colors.yellow })

hi('Type', { fg = colors.cyan, style = 'bold' })
hi('StorageClass', { fg = colors.cyan })
hi('Structure', { fg = colors.cyan })
hi('Typedef', { fg = colors.cyan })

hi('Special', { fg = colors.magenta })
hi('SpecialChar', { fg = colors.orange })
hi('Tag', { fg = colors.blue })
hi('Delimiter', { fg = colors.fg })
hi('SpecialComment', { fg = colors.fg_dim, style = 'bold,italic' })
hi('Debug', { fg = colors.red })

hi('Underlined', { style = 'underline' })
hi('Ignore', { fg = colors.fg_dim })
hi('Error', { fg = colors.red, style = 'bold,underline' })
hi('Todo', { fg = colors.magenta, bg = colors.bg, style = 'bold,italic' })

-- LSP
hi('DiagnosticError', { fg = colors.red })
hi('DiagnosticWarn', { fg = colors.yellow })
hi('DiagnosticInfo', { fg = colors.cyan })
hi('DiagnosticHint', { fg = colors.blue })

hi('DiagnosticUnderlineError', { sp = colors.red, style = 'undercurl' })
hi('DiagnosticUnderlineWarn', { sp = colors.yellow, style = 'undercurl' })
hi('DiagnosticUnderlineInfo', { sp = colors.cyan, style = 'undercurl' })
hi('DiagnosticUnderlineHint', { sp = colors.blue, style = 'undercurl' })

-- Treesitter
hi('@variable', { fg = colors.fg })
hi('@variable.builtin', { fg = colors.red })
hi('@variable.parameter', { fg = colors.red })
hi('@variable.member', { fg = colors.red })

hi('@constant', { fg = colors.orange })
hi('@constant.builtin', { fg = colors.orange })
hi('@constant.macro', { fg = colors.magenta })

hi('@string', { fg = colors.green })
hi('@string.escape', { fg = colors.cyan })
hi('@string.regex', { fg = colors.cyan })

hi('@number', { fg = colors.orange })
hi('@boolean', { fg = colors.orange })

hi('@function', { fg = colors.blue, style = 'bold' })
hi('@function.builtin', { fg = colors.blue })
hi('@function.macro', { fg = colors.magenta })
hi('@function.method', { fg = colors.blue })

hi('@keyword', { fg = colors.purple, style = 'bold' })
hi('@keyword.function', { fg = colors.purple, style = 'bold' })
hi('@keyword.operator', { fg = colors.purple })
hi('@keyword.return', { fg = colors.purple, style = 'bold' })

hi('@conditional', { fg = colors.purple, style = 'bold' })
hi('@repeat', { fg = colors.purple, style = 'bold' })
hi('@label', { fg = colors.purple })

hi('@operator', { fg = colors.cyan })

hi('@type', { fg = colors.cyan, style = 'bold' })
hi('@type.builtin', { fg = colors.cyan })
hi('@type.qualifier', { fg = colors.purple })

hi('@comment', { fg = colors.fg_dim, style = 'italic' })

hi('@punctuation.bracket', { fg = colors.fg })
hi('@punctuation.delimiter', { fg = colors.fg })
hi('@punctuation.special', { fg = colors.magenta })

hi('@tag', { fg = colors.blue })
hi('@tag.attribute', { fg = colors.orange })
hi('@tag.delimiter', { fg = colors.fg_dim })

-- Markdown
hi('@markup.heading', { fg = colors.blue, style = 'bold' })
hi('@markup.strong', { style = 'bold' })
hi('@markup.italic', { style = 'italic' })
hi('@markup.link', { fg = colors.cyan, style = 'underline' })
hi('@markup.raw', { fg = colors.green })
hi('@markup.list', { fg = colors.purple })

-- Git signs
hi('GitSignsAdd', { fg = colors.green })
hi('GitSignsChange', { fg = colors.yellow })
hi('GitSignsDelete', { fg = colors.red })

-- Diff colors for statusline (ensure white text)
hi('DiffAdded', { fg = '#ffffff' })
hi('DiffChanged', { fg = '#ffffff' })
hi('DiffRemoved', { fg = '#ffffff' })

-- Telescope
hi('TelescopeBorder', { fg = colors.ui_blue })
hi('TelescopePromptBorder', { fg = colors.ui_blue })
hi('TelescopeResultsBorder', { fg = colors.ui_blue })
hi('TelescopePreviewBorder', { fg = colors.ui_blue })
hi('TelescopeSelection', { fg = colors.fg, bg = colors.ui_blue_light, style = 'bold' })
hi('TelescopeMultiSelection', { fg = colors.fg, bg = colors.selection })

-- Which-key
hi('WhichKey', { fg = colors.blue, style = 'bold' })
hi('WhichKeyGroup', { fg = colors.purple })
hi('WhichKeyDesc', { fg = colors.fg })
hi('WhichKeySeparator', { fg = colors.fg_dim })

-- Terminal colors
vim.g.terminal_color_0 = colors.bg
vim.g.terminal_color_1 = colors.red
vim.g.terminal_color_2 = colors.green
vim.g.terminal_color_3 = colors.yellow
vim.g.terminal_color_4 = colors.blue
vim.g.terminal_color_5 = colors.purple
vim.g.terminal_color_6 = colors.cyan
vim.g.terminal_color_7 = colors.fg
vim.g.terminal_color_8 = colors.fg_dim
vim.g.terminal_color_9 = colors.red
vim.g.terminal_color_10 = colors.green
vim.g.terminal_color_11 = colors.yellow
vim.g.terminal_color_12 = colors.blue
vim.g.terminal_color_13 = colors.purple
vim.g.terminal_color_14 = colors.cyan
vim.g.terminal_color_15 = colors.fg

-- Mode-based current line color changes
local mode_group = vim.api.nvim_create_augroup('BoochtekModeColors', { clear = true })

-- Set initial CursorLine highlight (normal mode default)
vim.api.nvim_set_hl(0, 'CursorLine', { bg = colors.ui_blue_light })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = colors.blue, bg = colors.ui_blue_light, bold = true })

-- Mode-based current line colors using ModeChanged
vim.api.nvim_create_autocmd('ModeChanged', {
  group = mode_group,
  callback = function()
    local mode = vim.fn.mode()
    if mode == 'i' or mode == 'ic' or mode == 'ix' then
      -- Insert mode: light red current line
      vim.api.nvim_set_hl(0, 'CursorLine', { bg = colors.ui_red_light })
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = colors.red, bg = colors.ui_red_light, bold = true })
    elseif mode == 'v' or mode == 'V' or mode == '\x16' then
      -- Visual mode: light orange current line (matching gutter), light yellow selection
      vim.api.nvim_set_hl(0, 'Visual', { bg = colors.ui_yellow_light })
      vim.api.nvim_set_hl(0, 'CursorLine', { bg = colors.ui_orange_light })
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = colors.orange, bg = colors.ui_orange_light, bold = true })
      vim.api.nvim_set_hl(0, 'CursorLineFold', { link = 'CursorLine' })
      vim.api.nvim_set_hl(0, 'CursorLineSign', { link = 'CursorLine' })
    else
      -- Normal mode: gray current line
      vim.api.nvim_set_hl(0, 'CursorLine', { bg = colors.ui_blue_light })
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = colors.blue, bg = colors.ui_blue_light, bold = true })
      vim.api.nvim_set_hl(0, 'Visual', { bg = colors.selection })
    end
  end,
})
