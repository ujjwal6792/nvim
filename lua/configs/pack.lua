local gh = function(repo)
  return "https://github.com/" .. repo
end

local specs = {
  { src = gh "catppuccin/nvim", name = "catppuccin" },
  { src = gh "nvim-tree/nvim-web-devicons" },
  { src = gh "nvim-lua/plenary.nvim" },

  { src = gh "nvim-treesitter/nvim-treesitter" },
  { src = gh "numToStr/Comment.nvim" },
  { src = gh "JoosepAlviste/nvim-ts-context-commentstring" },
  { src = gh "nvim-tree/nvim-tree.lua" },
  { src = gh "nvim-telescope/telescope.nvim" },
  { src = gh "lewis6991/gitsigns.nvim" },
  { src = gh "folke/which-key.nvim" },

  { src = gh "mason-org/mason.nvim" },
  { src = gh "neovim/nvim-lspconfig" },
  { src = gh "stevearc/conform.nvim" },
  { src = gh "saghen/blink.cmp", version = "v1" },
  { src = gh "rafamadriz/friendly-snippets" },

  { src = gh "nvim-mini/mini.nvim" },
  { src = gh "kdheepak/lazygit.nvim" },
  { src = gh "mikavilpas/yazi.nvim" },
  { src = gh "nvim-pack/nvim-spectre" },
  { src = gh "rmagatti/auto-session" },

  { src = gh "amrbashir/nvim-docs-view" },
  { src = gh "3rd/image.nvim" },
  { src = gh "3rd/diagram.nvim" },
  { src = gh "OXY2DEV/markview.nvim" },
  { src = gh "gunasekar/markview-smart-tables.nvim" },
  { src = gh "vuki656/package-info.nvim" },
  { src = gh "MunifTanjim/nui.nvim" },

  { src = gh "mrcjkb/rustaceanvim", version = vim.version.range "6" },
  { src = gh "saecki/crates.nvim" },
  { src = gh "windwp/nvim-ts-autotag" },
  { src = gh "dsznajder/vscode-es7-javascript-react-snippets" },
}

local ok, err = pcall(vim.pack.add, specs, { load = true, confirm = false })
if not ok then
  vim.schedule(function()
    vim.notify("vim.pack.add failed: " .. err, vim.log.levels.ERROR)
  end)
end
