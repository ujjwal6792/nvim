local ok, mason = pcall(require, "mason")
if not ok then
  return
end

mason.setup()

vim.schedule(function()
  local ok_reg, registry = pcall(require, "mason-registry")
  if not ok_reg then
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
  } do
    local ok_pkg, pkg = pcall(registry.get_package, package)
    if ok_pkg and not pkg:is_installed() then
      pkg:install()
    end
  end
end)
