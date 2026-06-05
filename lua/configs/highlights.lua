local M = {}

local function palette()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if ok then
    return palettes.get_palette "mocha"
  end

  return {
    base = "#1e1e2e",
    mantle = "#181825",
    crust = "#11111b",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    text = "#cdd6f4",
    subtext0 = "#a6adc8",
    subtext1 = "#bac2de",
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    overlay2 = "#9399b2",
    green = "#a6e3a1",
    blue = "#89b4fa",
    mauve = "#cba6f7",
    teal = "#94e2d5",
    sky = "#89dceb",
    maroon = "#eba0ac",
    lavender = "#b4befe",
    rosewater = "#f5e0dc",
    flamingo = "#f2cdcd",
    pink = "#f5c2e7",
    red = "#f38ba8",
    peach = "#fab387",
    yellow = "#f9e2af",
  }
end

function M.apply()
  local c = palette()

  -- General UI overrides for a modern, flat, poppy look
  vim.api.nvim_set_hl(0, "Normal", { fg = c.text, bg = c.base })
  vim.api.nvim_set_hl(0, "NormalNC", { fg = c.text, bg = c.base })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = c.surface0 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c.peach, bold = true }) -- Warm peach for current line number
  vim.api.nvim_set_hl(0, "LineNr", { fg = c.overlay0 })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = c.surface1, bg = c.base })
  vim.api.nvim_set_hl(0, "Visual", { bg = c.surface1 })
  vim.api.nvim_set_hl(0, "Search", { fg = c.crust, bg = c.yellow, bold = true })
  vim.api.nvim_set_hl(0, "IncSearch", { fg = c.crust, bg = c.pink, bold = true }) -- Pink accent for incsearch

  -- Statusline
  vim.api.nvim_set_hl(0, "StatusLine", { fg = c.text, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c.subtext0, bg = c.mantle, italic = false })
  
  -- Soothing and poppy warm statusline mode colors (no cold blue/teal)
  vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = c.crust, bg = c.peach, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = c.crust, bg = c.pink, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = c.crust, bg = c.mauve, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = c.crust, bg = c.red, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = c.crust, bg = c.yellow, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { fg = c.crust, bg = c.flamingo, bold = true, italic = false })
  
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { fg = c.subtext1, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = c.text, bg = c.surface1, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = c.subtext1, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = c.subtext0, bg = c.mantle, italic = false })
  
  -- Statusline sub-components
  vim.api.nvim_set_hl(0, "UserStatusGit", { fg = c.flamingo, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusDiff", { fg = c.rosewater, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusDiag", { fg = c.red, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusLsp", { fg = c.mauve, bg = c.surface0, bold = true })
  
  -- UI Borders and popups
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = c.pink, bg = c.base })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.text, bg = c.base })
  vim.api.nvim_set_hl(0, "Pmenu", { fg = c.text, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "PmenuSel", { fg = c.crust, bg = c.pink, bold = true })
  
  -- Blink.cmp highlights (consistency with Pmenu)
  vim.api.nvim_set_hl(0, "BlinkCmpMenu", { fg = c.text, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = c.surface1, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "BlinkCmpDoc", { fg = c.text, bg = c.mantle })
  vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = c.surface1, bg = c.mantle })
  vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = c.text })
  vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = c.mauve })

  -- Telescope (NvChad/AstroNvim borderless flat blocks)
  vim.api.nvim_set_hl(0, "TelescopeNormal", { fg = c.text, bg = c.mantle })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = c.mantle, bg = c.mantle })
  
  vim.api.nvim_set_hl(0, "TelescopePromptNormal", { fg = c.text, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = c.surface0, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = c.peach, bg = c.surface0 })
  
  vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { fg = c.text, bg = c.crust })
  vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = c.crust, bg = c.crust })
  
  vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = c.peach, bg = c.surface1, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { fg = c.peach, bg = c.surface1 })
  vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = c.pink, bold = true })
  
  vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = c.crust, bg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = c.crust, bg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = c.crust, bg = c.mauve, bold = true })
  
  -- NvimTree with warm folder styling and git statuses
  vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "NvimTreeSymlinkFolderName", { fg = c.flamingo })
  vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeClosedFolderIcon", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderIcon", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = c.overlay1 })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = c.overlay1 })
  vim.api.nvim_set_hl(0, "NvimTreeBookmarkIcon", { fg = c.pink })
  vim.api.nvim_set_hl(0, "NvimTreeGitDirtyIcon", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "NvimTreeGitStagedIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitNewIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitRenamedIcon", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileDirtyHL", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileStagedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileNewHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileRenamedHL", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderDirtyHL", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderStagedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderNewHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderRenamedHL", { fg = c.peach })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedIcon", { fg = c.pink })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedFileHL", { fg = c.pink })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedFolderHL", { fg = c.pink })
  vim.api.nvim_set_hl(0, "NvimTreeGitDeletedIcon", { fg = c.red })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileDeletedHL", { fg = c.red })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderDeletedHL", { fg = c.red })
  
  -- WhichKey (Warm styling)
  vim.api.nvim_set_hl(0, "WhichKey", { fg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = c.text })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = c.mauve })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = c.overlay0 })

  -- Mason (Consistent theme colors)
  vim.api.nvim_set_hl(0, "MasonHeader", { fg = c.crust, bg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MasonHighlight", { fg = c.pink })
  vim.api.nvim_set_hl(0, "MasonHighlightBlock", { fg = c.crust, bg = c.pink })
  vim.api.nvim_set_hl(0, "MasonHighlightBlockSecondary", { fg = c.crust, bg = c.peach })
  vim.api.nvim_set_hl(0, "MasonMuted", { fg = c.overlay1 })
  vim.api.nvim_set_hl(0, "MasonMutedBlock", { fg = c.text, bg = c.surface0 })

  -- mini.starter beautiful highlights with high-contrast active item readable selection
  vim.api.nvim_set_hl(0, "MiniStarterHeader", { fg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterSection", { fg = c.mauve, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterItem", { fg = c.text })
  vim.api.nvim_set_hl(0, "MiniStarterItemBullet", { fg = c.peach })
  vim.api.nvim_set_hl(0, "MiniStarterQuery", { fg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterCurrent", { fg = c.pink, bg = c.surface1, bold = true })
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserHighlights", { clear = true }),
    callback = M.apply,
  })
end

return M
