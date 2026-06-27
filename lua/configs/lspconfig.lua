local capabilities = vim.lsp.protocol.make_client_capabilities()

local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink and blink.get_lsp_capabilities then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

if capabilities.workspace then
  capabilities.workspace.didChangeWatchedFiles = nil
end

local function on_attach(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts "go to declaration")
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts "go to definition")
  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "add workspace folder")
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "remove workspace folder")
  vim.keymap.set("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "list workspace folders")
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts "go to type definition")
  vim.keymap.set("n", "<leader>ra", vim.lsp.buf.rename, opts "rename")
end

vim.diagnostic.config {
  virtual_text = { prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  underline = true,
  update_in_insert = true,
  float = { source = true },
}

vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("LspDiagnosticsFloat", { clear = true }),
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

vim.lsp.config("*", {
  capabilities = capabilities,
  on_attach = on_attach,
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath "config" .. "/lua",
        },
      },
    },
  },
})

vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("marksman", {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml", ".git" },
})

vim.lsp.config("svelte", {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "svelte.config.mjs", "package.json", ".git" },
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      group = vim.api.nvim_create_augroup("svelte_ondidchangetsorjsfile", { clear = true }),
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
})

vim.lsp.config("astro", {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = { "astro.config.js", "astro.config.mjs", "astro.config.ts", "package.json", ".git" },
  init_options = {
    configuration = {},
    typescript = {
      serverPath = vim.fs.normalize "~/.nvm/versions/node/v19.9.0/lib/node_modules/typescript/lib/tsserverlibrary.js",
    },
  },
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "typescriptreact",
    "javascriptreact",
    "javascript.jsx",
    "typescript.tsx",
    "css",
    "scss",
    "html",
    "svelte",
    "astro",
  },
  root_markers = {
    "tailwind.config.js",
    "tailwind.config.cjs",
    "tailwind.config.mjs",
    "tailwind.config.ts",
    "postcss.config.js",
    "postcss.config.cjs",
    "package.json",
    ".git",
  },
})

vim.lsp.config("prismals", {
  cmd = { "prisma-language-server", "--stdio" },
  filetypes = { "prisma" },
  root_markers = { "schema.prisma", ".git" },
  settings = {
    prisma = { enable = true },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  flags = { debounce_text_changes = 150 },
  settings = {
    gopls = {
      gofumpt = true,
      experimentalPostfixCompletions = true,
      staticcheck = true,
      usePlaceholders = true,
    },
  },
})

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--compile-commands-dir=.",
    "--query-driver=/Users/ace/.platformio/packages/toolchain-xtensa-esp32s3/bin/xtensa-esp32s3-elf-*",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", "platformio.ini", ".git" },
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { "package.json", ".git" },
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git" },
})

vim.lsp.config("dockerls", {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile", ".git" },
})

vim.lsp.config("docker_compose_language_service", {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml", ".git" },
})

vim.lsp.config("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "svelte",
    "astro",
  },
  root_markers = {
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.mjs",
    ".eslintrc.json",
    ".eslintrc.yaml",
    ".eslintrc.yml",
    "eslint.config.js",
    "eslint.config.cjs",
    "eslint.config.mjs",
    "eslint.config.ts",
    "package.json",
    ".git",
  },
  settings = {
    validate = "on",
    packageManager = nil,
    useESLintClass = false,
    experimental = { useFlatConfig = false },
    codeActionOnSave = { enable = false, mode = "all" },
    format = false, -- let conform/prettier handle formatting
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "location" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
})


for _, server in ipairs {
  "lua_ls",
  "ts_ls",
  "eslint",
  "marksman",
  "svelte",
  "astro",
  "tailwindcss",
  "prismals",
  "gopls",
  "clangd",
  "html",
  "cssls",
  "dockerls",
  "docker_compose_language_service",
} do
  vim.lsp.enable(server)
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "docker-compose*.yml", "docker-compose*.yaml", "compose*.yml", "compose*.yaml" },
  callback = function()
    vim.bo.filetype = "yaml.docker-compose"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "tsconfig*.json" },
  callback = function()
    vim.bo.filetype = "jsonc"
  end,
})

vim.g.rustaceanvim = {
  tools = {},
  server = {
    capabilities = capabilities,
    on_attach = function(_, bufnr)
      vim.keymap.set("n", "<leader>ra", vim.lsp.buf.code_action, { silent = true, buffer = bufnr, desc = "rust lsp actions" })
      vim.keymap.set("n", "<leader>rs", ":RustAnalyzer restart<CR>", { silent = true, buffer = bufnr, desc = "rust lsp restart" })
      vim.keymap.set("n", "<leader>re", function()
        vim.cmd.RustLsp "explainError"
      end, { silent = true, buffer = bufnr, desc = "rust explain errors" })
    end,
    default_settings = {
      ["rust-analyzer"] = {
        hover_actions = { auto_focus = true },
        assist = {
          importEnforceGranularity = true,
          importPrefix = "crate",
        },
        cargo = { allFeatures = true },
        inlayHints = { locationLinks = false },
        diagnostics = {
          enable = true,
          experimental = { enable = true },
        },
      },
    },
  },
  dap = {},
}
