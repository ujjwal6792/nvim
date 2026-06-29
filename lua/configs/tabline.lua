local M = {}

local function get_palette()
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
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    green = "#a6e3a1",
    rosewater = "#f5e0dc",
    red = "#f38ba8",
    peach = "#fab387",
    yellow = "#f9e2af",
    blue = "#89b4fa",
    mauve = "#cba6f7",
    teal = "#94e2d5",
    lavender = "#b4befe",
  }
end

function M.apply_highlights()
  local c = get_palette()
  local active_bg = NONE
  local active_fg = c.peach
  local active_modified_fg = c.yellow

  vim.api.nvim_set_hl(0, "UserTablineTree", { fg = c.surface2, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineFill", { fg = c.overlay0, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineCurrent", { fg = active_fg, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserTablineVisible", { fg = c.text, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineHidden", { fg = c.subtext0, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineModified", { fg = c.yellow, bg = c.crust, bold = true })
  vim.api.nvim_set_hl(0, "UserTablineModifiedCurrent", { fg = active_modified_fg, bg = active_bg, bold = true })
  vim.api.nvim_set_hl(0, "UserTablineFaded", { fg = c.text, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineModifiedFaded", { fg = c.text, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserTablineSeparator", { fg = c.surface1, bg = NONE })
  vim.api.nvim_set_hl(0, "UserTablineClose", { fg = c.red, bg = active_bg, bold = true })
  vim.api.nvim_set_hl(0, "UserTablineAccent", { fg = c.rosewater, bg = c.surface0, bold = true })
end

local function nvimtree_offset()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "NvimTree" then
      return vim.api.nvim_win_get_width(win)
    end
  end
  return 0
end

local function is_visible(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return true
    end
  end
  return false
end

local function listed_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "NvimTree" then
      table.insert(buffers, buf)
    end
  end
  table.sort(buffers)
  return buffers
end

local function is_work_buffer(buf)
  return vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "NvimTree" and vim.bo[buf].buftype == ""
end

local function buffer_label(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local label = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")

  local icon = " "
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok and name ~= "" then
    local file_icon = devicons.get_icon(label, vim.fn.fnamemodify(name, ":e"), { default = true })
    icon = file_icon and (file_icon .. " ") or ""
  end

  local state = vim.bo[buf].modified and " ●" or ""
  return icon .. label .. state
end

function M.make()
  local current = vim.api.nvim_get_current_buf()
  local parts = {}
  local offset = nvimtree_offset()
  local focused_work_buffer = is_work_buffer(current)

  if offset > 0 then
    table.insert(parts, "%#UserTablineTree#" .. string.rep(" ", offset))
  end

  for _, buf in ipairs(listed_buffers()) do
    local hl
    if not focused_work_buffer then
      hl = vim.bo[buf].modified and "UserTablineModifiedFaded" or "UserTablineFaded"
    elseif buf == current then
      hl = vim.bo[buf].modified and "UserTablineModifiedCurrent" or "UserTablineCurrent"
    elseif is_visible(buf) then
      hl = "UserTablineVisible"
    else
      hl = vim.bo[buf].modified and "UserTablineModified" or "UserTablineHidden"
    end

    table.insert(parts, "%#" .. hl .. "#")
    table.insert(parts, "%" .. buf .. "@UserTablineSwitchBuffer@")
    table.insert(parts, "  " .. buffer_label(buf):gsub("%%", "%%%%") .. " ")
    table.insert(parts, "%X")
    if focused_work_buffer and buf == current then
      table.insert(parts, "%#UserTablineClose#")
      table.insert(parts, "%" .. buf .. "@UserTablineCloseBuffer@")
      table.insert(parts, " 󰅖 ")
      table.insert(parts, "%X")
    else
      table.insert(parts, " ")
    end
    table.insert(parts, "%#UserTablineSeparator# ")
  end

  table.insert(parts, "%#UserTablineFill#%=")
  return table.concat(parts, "")
end

function M.setup()
  _G.UserTabline = M
  M.apply_highlights()
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.UserTabline.make()"

  vim.cmd [[
    function! UserTablineSwitchBuffer(buf_id, clicks, button, mod)
        call v:lua.require('configs.buffers').open_buffer(a:buf_id)
    endfunction
  ]]

  vim.cmd [[
    function! UserTablineCloseBuffer(buf_id, clicks, button, mod)
        call v:lua.require('configs.buffers').open_buffer(a:buf_id)
        call v:lua.require('configs.buffers').close_current()
    endfunction
  ]]

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserTabline", { clear = true }),
    callback = M.apply_highlights,
  })
end

return M
