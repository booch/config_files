# Neovim Color Theme Configuration

## Current Setup

Your Neovim is configured with 24-bit true color support and multiple light themes optimized for your preferences.

**Currently Active**: `bluloco-light` (with enhanced modeline and current line)

## Available Themes

1. **bluloco-light** (Default) - Great background colors with enhanced visibility
2. **onelight** (OneDarkPro) - Very colorful with Bluloco-inspired backgrounds
3. **PaperColor** - Clean and readable
4. **humanoid** - Balanced and easy on eyes
5. **Tomorrow** - Classic fallback

## Quick Commands

### Test Themes Temporarily
```vim
:ThemeTest bluloco-light
:ThemeTest onelight
:ThemeTest PaperColor
:ThemeTest humanoid
:ThemeTest Tomorrow
```

### Use Telescope to Browse
Press `<leader>th` (usually `<space>th`) to open a theme picker with live preview

### Set Permanently
Edit `~/.config/nvim/lua/custom/plugins/theme.lua` and uncomment the `vim.cmd('colorscheme ...')` line for your chosen theme.

## Features

✅ 24-bit true color support (`termguicolors` enabled)
✅ Enhanced current line visibility (light blue background)
✅ Bold, high-contrast modeline/statusline
✅ All themes optimized for light backgrounds
✅ Easy switching between themes

## Customization

### Current Enhancements Applied

**Bluloco-light** (active):
- Current line: `#E6F3FF` (light blue)
- Line number on current line: `#0099FF` (bold blue)
- Status line: `#0099FF` background with white text (bold)

**OneDarkPro (onelight)**:
- Maintains colorfulness with Bluloco-inspired backgrounds
- Enhanced modeline and current line definition

### Modify Further

To adjust colors, edit the `config` function for each theme in:
`~/.config/nvim/lua/custom/plugins/theme.lua`

## Testing Your Setup

1. Restart Neovim or run `:Lazy sync`
2. Try `:ThemeTest help` to see options
3. Test each theme with `:ThemeTest <name>`
4. Use `<space>th` for live preview
5. Once decided, edit theme.lua to make it permanent

## Note About Your Vim Config

Your existing `~/.vim/colors.vim` still loads after plugins. If you notice conflicts:
- Consider disabling old color settings in colors.vim
- Or set `vim.g.skip_colors_vim = true` in init.lua
