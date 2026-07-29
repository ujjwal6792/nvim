local ok, lint = pcall(require, "lint")
if not ok then
  return
end

-- Map filetypes to linters.
-- Note: eslint is handled by the eslint LSP server (lspconfig.lua),
-- so it is intentionally omitted here to avoid duplicate diagnostics.
lint.linters_by_ft = {
  -- Go
  go = { "golangci-lint", "staticcheck" },

  -- Docker
  dockerfile = { "hadolint" },

  -- Config files
  yaml = { "yamllint" },
  dotenv = { "dotenv_linter" },
  env = { "dotenv_linter" },
}

-- Trigger linting on these events
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
  callback = function()
    -- Only lint if the linter binary is available
    lint.try_lint(nil, { ignore_errors = true })
  end,
})
