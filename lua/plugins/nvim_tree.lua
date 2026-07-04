local ok, nvim_tree = pcall(require, "nvim-tree")
if not ok then
  return
end

local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"
  api.config.mappings.default_on_attach(bufnr)

  local function opts(desc)
    return {
      desc = "nvim-tree: " .. desc,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  local function open_in_work_window(node)
    node = node or api.tree.get_node_under_cursor()
    if node and node.type ~= "file" then
      api.node.open.edit(node)
      return
    end

    api.node.open.edit(node)
  end

  vim.keymap.set("n", "<CR>", open_in_work_window, opts "Open in Work Window")
  vim.keymap.set("n", "o", open_in_work_window, opts "Open in Work Window")
  vim.keymap.set("n", "<2-LeftMouse>", open_in_work_window, opts "Open in Work Window")
end

nvim_tree.setup {
  on_attach = nvim_tree_on_attach,
  filters = { dotfiles = false },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    width = 30,
    preserve_window_proportions = true,
  },
  actions = {
    open_file = {
      resize_window = false,
      window_picker = {
        enable = true,
        picker = function()
          return require("configs.buffers").pick_file_open_window()
        end,
        exclude = {
          filetype = { "NvimTree", "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame" },
          buftype = { "nofile", "terminal", "help", "prompt", "quickfix" },
        },
      },
    },
  },
  renderer = {
    root_folder_label = false,
    highlight_git = "name",
    highlight_modified = "name",
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
    },
  },
}

vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete", "BufWipeout" }, {
  group = vim.api.nvim_create_augroup("NvimTreeWidthGuard", { clear = true }),
  callback = function()
    require("configs.buffers").keep_nvimtree_width()
  end,
})
