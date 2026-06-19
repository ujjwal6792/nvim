local ok, blink = pcall(require, "blink.cmp")
if not ok then
  return
end

local lspkind = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰜢",
  Variable = "󰀫",
  Class = "󰠱",
  Interface = "",
  Module = "",
  Property = "󰜢",
  Unit = "󰑭",
  Value = "󰎠",
  Enum = "",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "󰈇",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "󰏿",
  Struct = "󰙅",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "",
}

local color_cache = {}

local function color_from_completion_item(item)
  local documentation = item and item.documentation
  if type(documentation) == "string" and documentation:match "^#%x%x%x%x%x%x$" then
    return documentation
  end

  if type(documentation) == "table" and type(documentation.value) == "string" then
    return documentation.value:match "#%x%x%x%x%x%x"
  end
end

local function color_hl(ctx)
  if ctx.kind ~= "Color" then
    return
  end

  local color = color_from_completion_item(ctx.item)
  if not color then
    return
  end

  local hl = "BlinkTailwindColor" .. color:sub(2)
  if not color_cache[hl] then
    vim.api.nvim_set_hl(0, hl, { fg = color })
    color_cache[hl] = true
  end
  return hl
end

blink.setup {
  keymap = {
    preset = "none",
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-d>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
  appearance = {
    nerd_font_variant = "normal",
  },
  completion = {
    trigger = {
      show_on_backspace = true,
      show_on_backspace_in_keyword = true,
    },
    documentation = {
      auto_show = true,
      window = { border = "single" },
    },
    menu = {
      border = "single",
      scrollbar = false,
      draw = {
        padding = { 1, 1 },
        columns = { { "label" }, { "kind_icon" }, { "kind" } },
        components = {
          kind_icon = {
            text = function(ctx)
              return lspkind[ctx.kind] or "󰈚"
            end,
            highlight = function(ctx)
              return color_hl(ctx) or "BlinkCmpKind" .. ctx.kind
            end,
          },
          kind = {
            highlight = function(ctx)
              return color_hl(ctx) or "BlinkCmpKind" .. ctx.kind
            end,
          },
        },
      },
    },
  },
  sources = {
    default = { "lsp", "path", "cwd_files", "snippets", "buffer" },
    providers = {
      cwd_files = {
        name = "CWD files",
        module = "configs.cwd_files",
        min_keyword_length = 1,
        score_offset = -2,
      },
    },
  },
  snippets = { preset = "default" },
  fuzzy = { implementation = "lua" },
}
