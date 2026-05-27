local function has(mod)
  local ok, loaded = pcall(require, mod)
  if ok then
    return loaded
  end
end

local catppuccin = has "catppuccin"
if catppuccin then
  catppuccin.setup {
    flavour = "mocha",
    integrations = {
      blink_cmp = true,
      gitsigns = true,
      markdown = true,
      mason = true,
      mini = true,
      native_lsp = { enabled = true },
      nvimtree = true,
      treesitter = true,
      which_key = true,
    },
    custom_highlights = function(colors)
      return {
        Comment = { fg = colors.overlay1, style = { "italic", "bold" } },
        ["@comment"] = { fg = colors.overlay1, style = { "italic", "bold" } },
      }
    end,
  }
  vim.cmd.colorscheme "catppuccin"
end

local devicons = has "nvim-web-devicons"
if devicons then
  devicons.setup { default = true }
end

local mini_ai = has "mini.ai"
if mini_ai then
  mini_ai.setup { n_lines = 1000 }
end

local mini_bracketed = has "mini.bracketed"
if mini_bracketed then
  mini_bracketed.setup()
end

local mini_move = has "mini.move"
if mini_move then
  mini_move.setup {
    mappings = {
      left = "<M-a>",
      right = "<M-d>",
      down = "<M-s>",
      up = "<M-w>",
      line_left = "<M-a>",
      line_right = "<M-d>",
      line_down = "<M-s>",
      line_up = "<M-w>",
    },
  }
end

local mini_statusline = has "mini.statusline"
if mini_statusline then
  mini_statusline.setup {
    use_icons = true,
    content = {
      active = function()
        local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
        local git = MiniStatusline.section_git { trunc_width = 40, icon = "" }
        local diff = MiniStatusline.section_diff { trunc_width = 75, icon = "" }
        local diagnostics = MiniStatusline.section_diagnostics {
          trunc_width = 75,
          icon = "󰒡",
          signs = { ERROR = "", WARN = "", INFO = "", HINT = "󰌵" },
        }
        local lsp = MiniStatusline.section_lsp { trunc_width = 75, icon = "" }
        local filename = "󰈙 " .. MiniStatusline.section_filename { trunc_width = 140 }
        local fileinfo = " " .. MiniStatusline.section_fileinfo { trunc_width = 120 }
        local location = "󰍒 " .. MiniStatusline.section_location { trunc_width = 75 }
        local search = MiniStatusline.section_searchcount { trunc_width = 75 }

        return MiniStatusline.combine_groups {
          { hl = mode_hl, strings = { " " .. mode } },
          { hl = "UserStatusGit", strings = { git } },
          { hl = "UserStatusDiff", strings = { diff } },
          { hl = "UserStatusDiag", strings = { diagnostics } },
          { hl = "UserStatusLsp", strings = { lsp } },
          "%<",
          { hl = "MiniStatuslineFilename", strings = { filename } },
          "%=",
          { hl = "MiniStatuslineFileinfo", strings = { search, fileinfo } },
          { hl = mode_hl, strings = { location } },
        }
      end,
    },
  }
end

require("configs.highlights").setup()
require("configs.tabline").setup()

local treesitter = has "nvim-treesitter.configs"
if treesitter then
  treesitter.setup {
    ensure_installed = {
      "astro",
      "scss",
      "svelte",
      "vim",
      "lua",
      "html",
      "css",
      "json",
      "javascript",
      "typescript",
      "tsx",
      "prisma",
      "go",
      "c",
      "rust",
      "markdown",
      "markdown_inline",
    },
    highlight = { enable = true },
    indent = { enable = true },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  }
end

local comment = has "Comment"
if comment then
  local pre_hook
  local ok, integration = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
  if ok then
    pre_hook = integration.create_pre_hook()
  end
  comment.setup { pre_hook = pre_hook }
end

local nvim_tree = has "nvim-tree"
if nvim_tree then
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
      require("configs.buffers").pick_file_open_window()
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
      highlight_git = true,
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
end

local telescope = has "telescope"
if telescope then
  local actions = require "telescope.actions"
  telescope.setup {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = " ",
      entry_prefix = " ",
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
        },
        width = 0.87,
        height = 0.80,
      },
      mappings = {
        n = { q = actions.close },
      },
    },
  }
  pcall(telescope.load_extension, "lazygit")
end

local gitsigns = has "gitsigns"
if gitsigns then
  gitsigns.setup()
end

local which_key = has "which-key"
if which_key then
  which_key.setup()
end

local mason = has "mason"
if mason then
  mason.setup()

  vim.schedule(function()
    local ok, registry = pcall(require, "mason-registry")
    if not ok then
      return
    end

    for _, package in ipairs {
      "lua-language-server",
      "stylua",
      "jq",
      "css-lsp",
      "html-lsp",
      "typescript-language-server",
      "deno",
      "prettier",
      "prettierd",
      "tailwindcss-language-server",
      "vale",
      "cssmodules-language-server",
      "eslint-lsp",
      "eslint_d",
      "prismals",
      "svelte-language-server",
      "astro-language-server",
      "dockerfile-language-server",
      "docker-compose-language-service",
      "yamlfmt",
      "taplo",
      "gopls",
      "golangci-lint",
      "clangd",
      "clang-format",
      "marksman",
    } do
      local ok_pkg, pkg = pcall(registry.get_package, package)
      if ok_pkg and not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end

local autotag = has "nvim-ts-autotag"
if autotag then
  autotag.setup()
end

local lazygit_group = vim.api.nvim_create_augroup("LazyGitChecktime", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = lazygit_group,
  pattern = "LazyGitExit",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and not vim.bo[buf].modified then
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" and vim.fn.filereadable(name) == 1 then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "silent! checktime"
          end)
        end
      end
    end
  end,
})

local yazi = has "yazi"
if yazi then
  yazi.setup {
    floating_window_scaling_factor = 0.75,
    open_for_directories = false,
    keymaps = {
      show_help = "<f1>",
    },
  }
end

local spectre = has "spectre"
if spectre then
  spectre.setup { open_cmd = "noswapfile vnew" }
end

local auto_session = has "auto-session"
if auto_session then
  auto_session.setup {
    cwd_change_handling = true,
    suppressed_dirs = { "~/" },
    session_lens = {
      load_on_setup = true,
      previewer = false,
      mappings = {
        delete_session = { "i", "<C-D>" },
        alternate_session = { "i", "<C-S>" },
        copy_session = { "i", "<C-Y>" },
      },
      theme_conf = { border = true },
    },
  }
end

local docs_view = has "docs-view"
if docs_view then
  docs_view.setup {
    position = "right",
    width = 60,
  }
end

if #vim.api.nvim_list_uis() > 0 then
  local image = has "image"
  if image then
    image.setup {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
        neorg = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "norg" },
        },
      },
      max_height_window_percentage = 50,
      kitty_method = "normal",
    }
  end
end

local markview = has "markview"
if markview then
  local markdown_filetypes = {
    ["markdown"] = true,
    ["markdown.mdx"] = true,
    ["quarto"] = true,
    ["rmd"] = true,
    ["typst"] = true,
    ["asciidoc"] = true,
  }

  markview.setup {
    preview = {
      filetypes = vim.tbl_keys(markdown_filetypes),
      ignore_buftypes = { "nofile", "terminal", "prompt", "quickfix", "help" },
      condition = function(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return false
        end

        local ft = vim.bo[buf].filetype
        if not markdown_filetypes[ft] then
          return false
        end

        local lang = vim.treesitter.language.get_lang(ft) or ft
        local ok = pcall(vim.treesitter.get_parser, buf, lang)
        return ok
      end,
    },
  }

  local actions = require "markview.actions"
  local original_set_query = actions.set_query
  actions.set_query = function(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local ft = vim.bo[buf].filetype
    if not markdown_filetypes[ft] then
      return
    end

    local lang = vim.treesitter.language.get_lang(ft) or ft
    local ok = pcall(vim.treesitter.get_parser, buf, lang)
    if not ok then
      return
    end

    return original_set_query(buf)
  end

  local ok_checkboxes, checkboxes = pcall(require, "markview.extras.checkboxes")
  if ok_checkboxes then
    checkboxes.setup()
  end
  local ok_editor, editor = pcall(require, "markview.extras.editor")
  if ok_editor then
    editor.setup()
  end
  local ok_headings, headings = pcall(require, "markview.extras.headings")
  if ok_headings then
    headings.setup()
  end
end

local package_info = has "package-info"
if package_info then
  package_info.setup { hide_unstable_versions = true }
end

local crates = has "crates"
if crates then
  crates.setup()
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

require "configs.blink"
