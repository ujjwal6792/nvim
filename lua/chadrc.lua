-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}
M.base46 = { theme = "catppuccin" }
M.ui = { -- hl = highlights
  hl_add = {},
  hl_override = {
    Comment = { italic = true, fg = "light_grey", bold = true },
    ["@comment"] = { italic = true, fg = "light_grey", bold = true },
  },
  theme_toggle = { "catppuccin" },
  theme = "catppuccin", -- default theme
  transparency = false,

  cmp = {
    -- icons = true,
    format_colors = {
      tailwind = true,
    },
    icons = true,
    lspkind_text = true,
    style = "default", -- default/flat_light/flat_dark/atom/atom_colored
  },

  telescope = { style = "borderless" }, -- borderless / bordered

  ------------------------------- nvchad_ui modules -----------------------------
  statusline = {
    theme = "minimal", -- default/vscode/vscode_colored/minimal
    -- default/round/block/arrow separators work only for default statusline theme
    -- round and block will work for minimal theme only
    separator_style = "round",
    order = nil,
    modules = nil,
  },

  -- lazyload it when there are 1+ buffers
  tabufline = {
    enabled = true,
    lazyload = true,
    order = { "treeOffset", "buffers", "tabs", "btns" },
    modules = nil,
  },
  lsp = { signature = true },
}

M.term = {
  startinsert = true,
  base46_colors = true,
  winopts = {
    number = false,
    relativenumber = false,
    winhl = "Normal:term,WinSeparator:WinSeparator",
  },
  sizes = { sp = 0.5, vsp = 0.5, ["bo sp"] = 0.5, ["bo vsp"] = 0.5 },
  float = {
    relative = "editor",
    row = 0.035,
    col = 0.035,
    width = 0.9,
    height = 0.9,
    border = "single",
  },
}

return M
