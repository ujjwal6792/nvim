local ok, conform = pcall(require, "conform")
if not ok then
  return
end

local util = require "conform.util"

local prettier_markers = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.cts",
  ".prettierrc.mts",
  ".prettierrc.toml",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
  "prettier.config.cts",
  "prettier.config.mts",
  "package.json",
}

conform.setup {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettierd", "prettier", stop_after_first = true },
    scss = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    svelte = { "prettierd", "prettier", stop_after_first = true },
    astro = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    jsonc = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    ["markdown.mdx"] = { "prettierd", "prettier", stop_after_first = true },
    toml = { "taplo" },
    go = { "gofumpt", "goimports", "gofmt", stop_after_first = true },
    c = { "clang_format" },
    cpp = { "clang_format" },
  },
  formatters = {
    prettier = {
      cwd = util.root_file(prettier_markers),
      require_cwd = true,
    },
    prettierd = {
      cwd = util.root_file(prettier_markers),
      require_cwd = true,
    },
    stylua = {
      cwd = util.root_file { "stylua.toml", ".stylua.toml" },
    },
    taplo = {
      cwd = util.root_file { "taplo.toml", ".taplo.toml", "Cargo.toml", ".git" },
    },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_format = "fallback",
    quiet = true,
  },
}
