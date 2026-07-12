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

  -- General UI overrides for a darker frosted glass look
  vim.api.nvim_set_hl(0, "Normal", { fg = c.text, bg = NONE })
  vim.api.nvim_set_hl(0, "NormalNC", { fg = c.surface1, bg = NONE })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = c.surface0 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c.peach, bold = true }) -- Warm peach for current line number
  vim.api.nvim_set_hl(0, "LineNr", { fg = c.overlay0 })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = c.surface1, bg = NONE })
  vim.api.nvim_set_hl(0, "Visual", { bg = c.surface1 })
  vim.api.nvim_set_hl(0, "Search", { fg = c.crust, bg = c.yellow, bold = true })
  vim.api.nvim_set_hl(0, "IncSearch", { fg = c.crust, bg = c.pink, bold = true }) -- Pink accent for incsearch

  -- Statusline (frosted glass: transparent bg)
  vim.api.nvim_set_hl(0, "StatusLine", { fg = c.text, bg = NONE, italic = false })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c.subtext0, bg = NONE, italic = false })

  -- Soothing mode colors (frosted glass: deeper backgrounds)
  vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = c.crust, bg = c.peach, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = c.crust, bg = c.pink, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = c.crust, bg = c.mauve, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = c.crust, bg = c.red, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = c.crust, bg = c.yellow, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { fg = c.crust, bg = c.flamingo, bold = true, italic = false })

  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { fg = c.subtext1, bg = NONE, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = c.text, bg = NONE, bold = true, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = c.subtext1, bg = NONE, italic = false })
  vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = c.subtext0, bg = NONE, italic = false })

  -- Statusline sub-components (frosted glass: transparent bg)
  vim.api.nvim_set_hl(0, "UserStatusGit", { fg = c.flamingo, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusDiff", { fg = c.rosewater, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusError", { fg = c.red, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusWarn", { fg = c.yellow, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusInfo", { fg = c.blue, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusHint", { fg = c.teal, bg = NONE, bold = true })
  vim.api.nvim_set_hl(0, "UserStatusLsp", { fg = c.mauve, bg = NONE, bold = true })

  -- UI Borders and popups (frosted glass: darker backgrounds + blend)
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = c.pink, bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.text, bg = "none" })
  vim.api.nvim_set_hl(0, "Pmenu", { fg = c.text, bg = c.mantle })
  vim.api.nvim_set_hl(0, "PmenuSel", { fg = c.crust, bg = c.pink, bold = true })

  -- Blink.cmp (darker frosted glass)
  vim.api.nvim_set_hl(0, "BlinkCmpMenu", { fg = c.text, bg = c.mantle })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = c.surface1, bg = c.mantle })
  vim.api.nvim_set_hl(0, "BlinkCmpDoc", { fg = c.text, bg = c.crust })
  vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = c.surface1, bg = c.crust })
  vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = c.text })
  vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = c.mauve })

  -- Telescope (frosted glass: deeper backgrounds)
  vim.api.nvim_set_hl(0, "TelescopeNormal", { fg = c.text, bg = c.crust })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = c.crust, bg = c.crust })

  vim.api.nvim_set_hl(0, "TelescopePromptNormal", { fg = c.text, bg = c.mantle })
  vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = c.mantle, bg = c.mantle })
  vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = c.peach, bg = c.mantle })

  vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { fg = c.text, bg = "#0d0d17" })
  vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = "#0d0d17", bg = "#0d0d17" })

  vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = c.peach, bg = c.surface1, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { fg = c.peach, bg = c.surface1 })
  vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = c.pink, bold = true })

  vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = c.crust, bg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = c.crust, bg = c.peach, bold = true })
  vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = c.crust, bg = c.mauve, bold = true })

  -- NvimTree (frosted glass sidebar)
  vim.api.nvim_set_hl(0, "NvimTreeNormal", { fg = c.text, bg = NONE })
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

  -- Mason (frosted glass: deeper backgrounds)
  vim.api.nvim_set_hl(0, "MasonHeader", { fg = c.crust, bg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MasonHighlight", { fg = c.pink })
  vim.api.nvim_set_hl(0, "MasonHighlightBlock", { fg = c.crust, bg = c.pink })
  vim.api.nvim_set_hl(0, "MasonHighlightBlockSecondary", { fg = c.crust, bg = c.peach })
  vim.api.nvim_set_hl(0, "MasonMuted", { fg = c.overlay1 })
  vim.api.nvim_set_hl(0, "MasonMutedBlock", { fg = c.text, bg = c.mantle })

  -- mini.starter (frosted glass)
  vim.api.nvim_set_hl(0, "MiniStarterHeader", { fg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterSection", { fg = c.mauve, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterItem", { fg = c.text })
  vim.api.nvim_set_hl(0, "MiniStarterItemBullet", { fg = c.peach })
  vim.api.nvim_set_hl(0, "MiniStarterQuery", { fg = c.pink, bold = true })
  vim.api.nvim_set_hl(0, "MiniStarterCurrent", { fg = c.pink, bg = c.surface0, bold = true })
  -- Custom highlights for jsonl task runner files
  -- ─── JSONL Task File Highlights ──────────────────────────────────────
  -- Design: row bg tints preserve JSON key readability; bold tokens pop.

  -- Row-level background tints (Priority 5)
  -- Using bg tints so JSON keys/colons/braces stay readable in their normal fg.
  vim.api.nvim_set_hl(0, "JsonlLineTodo",       { bg = NONE })                             -- default; no tint needed
  vim.api.nvim_set_hl(0, "JsonlLineInProgress", { bg = "#2a2520" })                       -- warm amber tint
  vim.api.nvim_set_hl(0, "JsonlLineBlocked",    { bg = "#251f1f" })                       -- subtle red tint
  vim.api.nvim_set_hl(0, "JsonlLineDone",       { fg = c.overlay0, italic = false })      -- muted fg only; done = greyed out

  -- Status VALUES (Priority 15 - always bold, always pop)
  vim.api.nvim_set_hl(0, "JsonlStatusTodo",       { fg = c.blue,   bold = true })          -- blue  → actionable
  vim.api.nvim_set_hl(0, "JsonlStatusInProgress", { fg = c.peach,  bold = true })          -- peach → active/warm
  vim.api.nvim_set_hl(0, "JsonlStatusBlocked",    { fg = c.red,    bold = true })          -- red   → danger/attention
  vim.api.nvim_set_hl(0, "JsonlStatusDone",       { fg = c.green,  bold = true })          -- green → complete

  -- Priority VALUES (Priority 12)
  vim.api.nvim_set_hl(0, "JsonlPriorityP0", { fg = c.red,      bold = true, underline = true }) -- P0 critical: red + underline
  vim.api.nvim_set_hl(0, "JsonlPriorityP1", { fg = c.peach,    bold = true })                   -- P1 high
  vim.api.nvim_set_hl(0, "JsonlPriorityP2", { fg = c.yellow,   bold = false })                  -- P2 medium; no bold to reduce noise
  vim.api.nvim_set_hl(0, "JsonlPriorityP3", { fg = c.overlay2, bold = false })                  -- P3 low; subdued

  -- Metadata token VALUES (Priority 12)
  vim.api.nvim_set_hl(0, "JsonlTaskId",     { fg = c.mauve,   bold = true })              -- ID: mauve bold = anchor identifier
  vim.api.nvim_set_hl(0, "JsonlSprint",     { fg = c.sky,     bold = false })             -- sprint: sky blue, light
  vim.api.nvim_set_hl(0, "JsonlMilestone",  { fg = c.lavender, bold = true })             -- milestone: lavender bold
  vim.api.nvim_set_hl(0, "JsonlEpic",       { fg = c.flamingo, bold = false })            -- epic: flamingo, distinct

  -- completed_at VALUE (Priority 15 - always teal when present)
  vim.api.nvim_set_hl(0, "JsonlCompletedAt", { fg = c.teal, bold = true })
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserHighlights", { clear = true }),
    callback = M.apply,
  })
end

return M
