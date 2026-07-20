local ok, mason = pcall(require, "mason")
if not ok then
  return
end

mason.setup()

local packages = {
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
  "cssmodules-language-server",
  "eslint-lsp",
  "eslint_d",
  "prismals",
  "svelte-language-server",
  "astro-language-server",
  "dockerfile-language-server",
  "docker-compose-language-service",
  "yamlfmt",
  "yamllint",
  "taplo",
  "gopls",
  "golangci-lint",
  "staticcheck",
  "clangd",
  "clang-format",
  "marksman",
  "hadolint",
  "dotenv-linter",
}

vim.api.nvim_create_autocmd("User", {
  pattern = "MasonInstall",
  group = vim.api.nvim_create_augroup("MasonPackages", { clear = true }),
  callback = function()
    local ok_reg, registry = pcall(require, "mason-registry")
    if not ok_reg then
      return
    end

    for _, package in ipairs(packages) do
      local ok_pkg, pkg = pcall(registry.get_package, package)
      if ok_pkg and not pkg:is_installed() then
        pkg:install()
      end
    end
  end,
})

vim.cmd("doautocmd User MasonInstall")
