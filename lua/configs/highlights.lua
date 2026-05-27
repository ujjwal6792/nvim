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
    green = "#a6e3a1",
    overlay0 = "#6c7086",
    rosewater = "#f5e0dc",
    red = "#f38ba8",
    peach = "#fab387",
    yellow = "#f9e2af",
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
