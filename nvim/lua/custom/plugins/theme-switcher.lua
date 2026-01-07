-- Theme switcher commands and keymaps

-- Setup custom commands first
vim.api.nvim_create_user_command('ThemeTest', function(opts)
  local theme = opts.args

  if theme == '' or theme == 'help' then
    print('Available light themes:')
    print('  onelight       - OneDarkPro (colorful with enhanced UI)')
    print('  PaperColor     - Clean and readable')
    print('  humanoid       - Balanced and easy on eyes')
    print('  bluloco-light  - Great backgrounds (current default)')
    print('  Tomorrow       - Classic fallback')
    print('')
    print('Usage: :ThemeTest <theme-name>')
    return
  end

  vim.cmd('colorscheme ' .. theme)
  if theme ~= 'onelight' and theme ~= 'bluloco-light' then
    vim.opt.background = 'light'
  end

  print('Applied theme: ' .. theme)
end, {
  nargs = '?',
  complete = function()
    return { 'onelight', 'PaperColor', 'humanoid', 'bluloco-light', 'Tomorrow' }
  end,
})

vim.api.nvim_create_user_command('ThemeSet', function(opts)
  local theme = opts.args
  if theme == '' then
    print('Usage: :ThemeSet <theme-name>')
    print('This will update your theme.lua to make the theme permanent.')
    return
  end

  print('To permanently set theme, uncomment the colorscheme line in:')
  print('~/.config/nvim/lua/custom/plugins/theme.lua')
  print('For theme: ' .. theme)
end, { nargs = 1 })

-- Setup keymap directly to avoid which-key recursion
vim.keymap.set('n', '<leader>th', '<cmd>Telescope colorscheme<cr>', { 
  desc = '[T]heme: Switch colorscheme',
  silent = true 
})

-- Empty return to satisfy plugin loader
return {}
