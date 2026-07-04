local ok, catppuccin = pcall(require, "catppuccin")
if not ok then
  return
end

catppuccin.setup {
  flavour = "mocha",
  transparent_background = true,
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = { "italic" },
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
  },
  integrations = {
    blink_cmp = true,
    gitsigns = true,
    markdown = true,
    mason = true,
    mini = true,
    native_lsp = { enabled = true },
    nvimtree = true,
    snacks = true,
    treesitter = true,
    which_key = true,
  },
  custom_highlights = function(colors)
    return {
      -- All windows fully transparent - only text visible over wallpaper
      Normal         = { bg = "NONE" },
      NormalNC       = { bg = "NONE" },
      NormalFloat    = { fg = colors.text, bg = "NONE" },
      FloatBorder    = { fg = colors.surface1, bg = "NONE" },

      -- Snacks internal highlight groups - all transparent
      SnacksNormal       = { fg = colors.text, bg = "NONE" },
      SnacksNormalNC     = { fg = colors.subtext0, bg = "NONE" },
      SnacksWinBar       = { fg = colors.subtext0, bg = "NONE" },
      SnacksWinSeparator = { fg = colors.surface1, bg = "NONE" },
      SnacksTitle        = { fg = colors.blue, bg = "NONE", bold = true },
      SnacksFooter       = { fg = colors.overlay1, bg = "NONE" },
      SnacksBackdrop     = { bg = "NONE", blend = 0 },

      -- Snacks picker specific
      SnacksPickerBorder   = { fg = colors.surface1, bg = "NONE" },
      SnacksPickerTitle    = { fg = colors.blue, bg = "NONE", bold = true },
      SnacksPickerFooter   = { fg = colors.overlay1, bg = "NONE" },
      SnacksPickerSelected = { fg = colors.mauve, bg = "NONE", bold = true },

      -- Dashboard transparent
      SnacksDashboardNormal  = { fg = colors.text, bg = "NONE" },
      SnacksDashboardHeader  = { fg = colors.blue, bg = "NONE" },
      SnacksDashboardFooter  = { fg = colors.overlay1, bg = "NONE" },
      SnacksDashboardTitle   = { fg = colors.blue, bg = "NONE", bold = true },
      SnacksDashboardSection = { fg = colors.mauve, bg = "NONE" },
      SnacksDashboardFile    = { fg = colors.text, bg = "NONE" },
      SnacksDashboardDir     = { fg = colors.subtext0, bg = "NONE" },
      SnacksDashboardKey     = { fg = colors.peach, bg = "NONE" },
      SnacksDashboardDesc    = { fg = colors.subtext1, bg = "NONE" },

      -- Statusline fully transparent
      StatusLine   = { bg = "NONE" },
      StatusLineNC = { bg = "NONE" },
      MiniStatuslineModeNormal  = { bg = "NONE", fg = colors.blue,   bold = true },
      MiniStatuslineModeInsert  = { bg = "NONE", fg = colors.green,  bold = true },
      MiniStatuslineModeVisual  = { bg = "NONE", fg = colors.mauve,  bold = true },
      MiniStatuslineModeReplace = { bg = "NONE", fg = colors.red,    bold = true },
      MiniStatuslineModeCommand = { bg = "NONE", fg = colors.peach,  bold = true },
      MiniStatuslineDevinfo     = { bg = "NONE", fg = colors.subtext1 },
      MiniStatuslineFileinfo    = { bg = "NONE", fg = colors.subtext1 },
      MiniStatuslineFilename    = { bg = "NONE", fg = colors.text },
      MiniStatuslineInactive    = { bg = "NONE", fg = colors.surface2 },
      Comment = { fg = colors.overlay1, style = { "italic" } },
      ["@comment"] = { fg = colors.overlay1, style = { "italic" } },
      ["@function"] = { fg = colors.blue, style = { "bold" } },
      ["@function.builtin"] = { fg = colors.blue, style = { "bold", "italic" } },
      ["@function.call"] = { fg = colors.blue, style = { "bold" } },
      ["@keyword"] = { fg = colors.mauve, style = { "italic" } },
      ["@keyword.function"] = { fg = colors.mauve, style = { "italic" } },
      ["@conditional"] = { fg = colors.mauve, style = { "italic" } },
      ["@repeat"] = { fg = colors.mauve, style = { "italic" } },
      ["@parameter"] = { fg = colors.maroon, style = { "italic" } },
      ["@variable"] = { fg = colors.text },
      ["@variable.builtin"] = { fg = colors.red, style = { "italic" } },
      ["@variable.member"] = { fg = colors.teal },
      ["@property"] = { fg = colors.teal },
      ["@field"] = { fg = colors.teal },
      ["@constant"] = { fg = colors.peach, style = { "bold" } },
      ["@constant.builtin"] = { fg = colors.peach, style = { "bold", "italic" } },
      ["@number"] = { fg = colors.peach },
      ["@boolean"] = { fg = colors.peach, style = { "bold" } },
      ["@string"] = { fg = colors.green },
      ["@string.regex"] = { fg = colors.peach },
      ["@type"] = { fg = colors.yellow },
      ["@type.builtin"] = { fg = colors.yellow, style = { "italic" } },
      ["@operator"] = { fg = colors.sky },
      ["@punctuation.bracket"] = { fg = colors.overlay2 },
      ["@punctuation.delimiter"] = { fg = colors.overlay2 },
      ["@tag"] = { fg = colors.red },
      ["@tag.attribute"] = { fg = colors.yellow, style = { "italic" } },
      ["@tag.delimiter"] = { fg = colors.sky },
    }
  end,
}
vim.cmd.colorscheme "catppuccin"
