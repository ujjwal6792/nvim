local M = {}

local function palette()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if ok then
    return palettes.get_palette "macchiato"
  end

  return {
    base = "#24273a",
    mantle = "#1e2030",
    crust = "#181926",
    surface0 = "#363a4f",
    surface1 = "#494d64",
    surface2 = "#5b6078",
    text = "#cad3f5",
    subtext0 = "#a5adcb",
    green = "#a6da95",
    overlay0 = "#6e738d",
    rosewater = "#f4dbd6",
    red = "#ed8796",
    peach = "#f5a97f",
    yellow = "#eed49f",
  }
end

function M.apply()
  local c = palette()

  vim.api.nvim_set_hl(0, "StatusLine", { fg = c.text, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c.subtext0, bg = c.mantle, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = c.crust, bg = c.green, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = c.crust, bg = c.yellow, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = c.crust, bg = c.peach, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = c.crust, bg = c.red, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = c.crust, bg = c.peach, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { fg = c.crust, bg = c.green, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { fg = c.green, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = c.rosewater, bg = c.surface1, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = c.yellow, bg = c.surface0, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = c.subtext0, bg = c.mantle, italic = false })
  vim.api.nvim_set_hl(0, "UserStatusGit", { fg = c.green, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusDiff", { fg = c.yellow, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusDiag", { fg = c.red, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusLsp", { fg = c.peach, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = c.peach, bg = c.base })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.text, bg = c.base })
  vim.api.nvim_set_hl(0, "Pmenu", { fg = c.text, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "PmenuSel", { fg = c.crust, bg = c.yellow, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { fg = c.text, bg = c.base })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = c.peach, bg = c.base })
  vim.api.nvim_set_hl(0, "TelescopePromptNormal", { fg = c.text, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = c.yellow, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = c.red, bg = c.surface0 })
  vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = c.crust, bg = c.green, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = c.yellow, bg = c.surface0, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = c.crust, bg = c.green, bold = true })
  vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = c.crust, bg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = c.crust, bg = c.red, bold = true })
  vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = "#F9B388", bold = true })
  vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeSymlinkFolderName", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeClosedFolderIcon", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderIcon", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeBookmarkIcon", { fg = "#F9B388" })
  vim.api.nvim_set_hl(0, "NvimTreeGitDirtyIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitStagedIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitNewIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitRenamedIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileDirtyHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileStagedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileNewHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileRenamedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderDirtyHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderStagedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderNewHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderRenamedHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedIcon", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedFileHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeModifiedFolderHL", { fg = c.green })
  vim.api.nvim_set_hl(0, "NvimTreeGitDeletedIcon", { fg = c.red })
  vim.api.nvim_set_hl(0, "NvimTreeGitFileDeletedHL", { fg = c.red })
  vim.api.nvim_set_hl(0, "NvimTreeGitFolderDeletedHL", { fg = c.red })
  vim.api.nvim_set_hl(0, "WhichKey", { fg = c.green, bold = true })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = c.yellow })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = c.peach })
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserHighlights", { clear = true }),
    callback = M.apply,
  })
end

return M
