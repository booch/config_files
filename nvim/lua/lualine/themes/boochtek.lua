-- Boochtek lualine theme
-- This theme dynamically updates based on mode

local colors = {
  bg = '#F9F9F9',
  fg = '#383A42',
  red = '#C03030',
  green = '#3D7D3C',
  blue = '#2F5CC0',
  orange = '#DA8548',
  yellow = '#F0A83E',
  gray = '#D0D0D0',
  gray_dark = '#505050',
}

-- Helper to create lighter shades
local function lighten(hex, amount)
  local r = tonumber(hex:sub(2,3), 16)
  local g = tonumber(hex:sub(4,5), 16)
  local b = tonumber(hex:sub(6,7), 16)

  r = math.min(255, r + amount)
  g = math.min(255, g + amount)
  b = math.min(255, b + amount)

  return string.format('#%02X%02X%02X', r, g, b)
end

-- Helper to create darker shades
local function darken(hex, amount)
  local r = tonumber(hex:sub(2,3), 16)
  local g = tonumber(hex:sub(4,5), 16)
  local b = tonumber(hex:sub(6,7), 16)

  r = math.max(0, r - amount)
  g = math.max(0, g - amount)
  b = math.max(0, b - amount)

  return string.format('#%02X%02X%02X', r, g, b)
end

local boochtek = {}

-- Normal mode (light edges, dark middle) - white text
boochtek.normal = {
  a = { fg = '#ffffff', bg = lighten(colors.blue, 25), gui = 'bold' },
  b = { fg = '#ffffff', bg = colors.blue },
  c = { fg = '#ffffff', bg = darken(colors.blue, 15) },
  x = { fg = '#ffffff', bg = darken(colors.blue, 15) },
  y = { fg = '#ffffff', bg = colors.blue },
  z = { fg = '#ffffff', bg = lighten(colors.blue, 25) },
}

-- Insert mode (light edges, dark middle) - white text
boochtek.insert = {
  a = { fg = '#ffffff', bg = lighten(colors.red, 30), gui = 'bold' },
  b = { fg = '#ffffff', bg = colors.red },
  c = { fg = '#ffffff', bg = darken(colors.red, 15) },
  x = { fg = '#ffffff', bg = darken(colors.red, 15) },
  y = { fg = '#ffffff', bg = colors.red },
  z = { fg = '#ffffff', bg = lighten(colors.red, 30) },
}

-- Visual mode (light edges, dark middle) - white text
boochtek.visual = {
  a = { fg = '#ffffff', bg = lighten(colors.orange, 20), gui = 'bold' },
  b = { fg = '#ffffff', bg = colors.orange },
  c = { fg = '#ffffff', bg = darken(colors.orange, 20) },
  x = { fg = '#ffffff', bg = darken(colors.orange, 20) },
  y = { fg = '#ffffff', bg = colors.orange },
  z = { fg = '#ffffff', bg = lighten(colors.orange, 20) },
}

-- Replace mode (light edges, dark middle) - white text
boochtek.replace = {
  a = { fg = '#ffffff', bg = lighten(colors.red, 30), gui = 'bold' },
  b = { fg = '#ffffff', bg = colors.red },
  c = { fg = '#ffffff', bg = darken(colors.red, 15) },
  x = { fg = '#ffffff', bg = darken(colors.red, 15) },
  y = { fg = '#ffffff', bg = colors.red },
  z = { fg = '#ffffff', bg = lighten(colors.red, 30) },
}

-- Command mode (light edges, dark middle) - white text
boochtek.command = {
  a = { fg = '#ffffff', bg = lighten(colors.green, 35), gui = 'bold' },
  b = { fg = '#ffffff', bg = colors.green },
  c = { fg = '#ffffff', bg = darken(colors.green, 10) },
  x = { fg = '#ffffff', bg = darken(colors.green, 10) },
  y = { fg = '#ffffff', bg = colors.green },
  z = { fg = '#ffffff', bg = lighten(colors.green, 35) },
}

-- Inactive
boochtek.inactive = {
  a = { fg = colors.gray_dark, bg = colors.gray },
  b = { fg = colors.gray_dark, bg = colors.gray },
  c = { fg = colors.gray_dark, bg = colors.gray },
}

return boochtek
