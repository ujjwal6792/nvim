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
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    svelte = { "prettier" },
    astro = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    ["markdown.mdx"] = { "prettier" },
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
    stylua = {
      cwd = util.root_file { "stylua.toml", ".stylua.toml" },
    },
    taplo = {
      cwd = util.root_file { "taplo.toml", ".taplo.toml", "Cargo.toml", ".git" },
    },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "fallback",
    quiet = true,
  },
}
