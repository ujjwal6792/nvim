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
      treesitter = true,
      which_key = true,
    },
    custom_highlights = function(colors)
      return {
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

local mini_starter = has "mini.starter"
if mini_starter then
  mini_starter.setup {
    autoopen = false,
    evaluate_single = true,
    items = {
      mini_starter.sections.builtin_actions(),
      function()
        return {
          { name = "Restore Session", action = "AutoSession restore", section = "Session" },
        }
      end,
      mini_starter.sections.recent_files(8, false, false),
      mini_starter.sections.recent_files(8, true, false),
    },
    content_hooks = {
      mini_starter.gen_hook.adding_bullet(),
      mini_starter.gen_hook.aligning("center", "center"),
    },
    query_updaters = "",
  }

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("UserMiniStarter", { clear = true }),
    once = true,
    callback = function()
      if vim.fn.argc() > 0 then
        return
      end

      local listed = vim.tbl_filter(function(buf)
        return vim.bo[buf].buflisted
      end, vim.api.nvim_list_bufs())
      local current = vim.api.nvim_get_current_buf()
      local is_empty = vim.api.nvim_buf_get_name(current) == ""
        and vim.api.nvim_buf_line_count(current) == 1
        and vim.api.nvim_buf_get_lines(current, 0, 1, false)[1] == ""

      if #listed <= 1 and is_empty then
        local dashboard = vim.api.nvim_create_buf(false, true)
        mini_starter.open(dashboard)
        if type(current) == "number" and vim.api.nvim_buf_is_valid(current) then
          pcall(vim.api.nvim_buf_delete, current, {})
        end
      end
    end,
  })
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
        local mode, mode_hl = mini_statusline.section_mode { trunc_width = 120 }
        local git = mini_statusline.section_git { trunc_width = 40, icon = "" }
        local diff = mini_statusline.section_diff { trunc_width = 75, icon = "" }
        local diag = vim.diagnostic.count(0)
        local function severity_text(sev, icon)
          local n = diag[sev] or 0
          return n > 0 and (icon .. " " .. n) or ""
        end

        local err_str = severity_text(vim.diagnostic.severity.ERROR, "")
        local warn_str = severity_text(vim.diagnostic.severity.WARN, "")
        local info_str = severity_text(vim.diagnostic.severity.INFO, "")
        local hint_str = severity_text(vim.diagnostic.severity.HINT, "󰌵")
        local lsp = mini_statusline.section_lsp { trunc_width = 75, icon = "" }
        local filename = "󰈙 " .. mini_statusline.section_filename { trunc_width = 140 }
        local fileinfo = " " .. mini_statusline.section_fileinfo { trunc_width = 120 }
        local location = "󰍒 " .. mini_statusline.section_location { trunc_width = 75 }
        local search = mini_statusline.section_searchcount { trunc_width = 75 }

        return mini_statusline.combine_groups {
          { hl = mode_hl, strings = { " " .. mode } },
          { hl = "UserStatusGit", strings = { git } },
          { hl = "UserStatusDiff", strings = { diff } },
          { hl = "UserStatusError", strings = { err_str } },
          { hl = "UserStatusWarn", strings = { warn_str } },
          { hl = "UserStatusInfo", strings = { info_str } },
          { hl = "UserStatusHint", strings = { hint_str } },
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
require "configs.autoread"

local treesitter = has "nvim-treesitter"
if treesitter then
  local parsers = {
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
    "cpp",
    "rust",
    "proto",
    "markdown",
    "markdown_inline",
  }

  treesitter.setup {
    install_dir = vim.fn.stdpath "data" .. "/site",
  }
  if vim.fn.executable "tree-sitter" == 1 then
    treesitter.install(parsers)
  else
    vim.schedule(function()
      vim.notify("Install tree-sitter CLI to enable missing Treesitter parsers and folds", vim.log.levels.WARN)
    end)
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
    callback = function(args)
      if pcall(vim.treesitter.start, args.buf) then
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })
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
    require("configs.autoread").sync()
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
  local function restore_launch_cwd()
    local cwd = vim.g.launch_cwd or vim.uv.cwd()
    if not cwd or cwd == "" then
      return
    end

    vim.cmd("cd " .. vim.fn.fnameescape(cwd))
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, function()
          vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
        end)
      end
    end

    vim.schedule(function()
      local ok, api = pcall(require, "nvim-tree.api")
      if ok then
        pcall(api.tree.change_root, cwd)
        pcall(api.tree.reload)
      end
      require("configs.buffers").keep_nvimtree_width()
    end)
  end

  auto_session.setup {
    auto_restore = false,
    auto_restore_enabled = false,
    close_filetypes_on_save = { "NvimTree", "terminal" },
    cwd_change_handling = false,
    suppressed_dirs = { "~/" },
    post_restore_cmds = {
      restore_launch_cwd,
      function()
        local cwd = vim.fn.getcwd()
        local cwd_prefix = vim.fn.fnamemodify(cwd, ":p")
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= "" and vim.bo[buf].buftype == "" then
              local abs_path = vim.fn.fnamemodify(name, ":p")
              if abs_path:sub(1, #cwd_prefix) ~= cwd_prefix then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
          end
        end
      end,
    },
    no_restore_cmds = {
      function()
        restore_launch_cwd()
      end,
    },
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
