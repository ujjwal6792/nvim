local gh = function(repo)
  return "https://github.com/" .. repo
end

local M = {}

M.specs = {
  { src = gh "catppuccin/nvim", name = "catppuccin" },
  { src = gh "nvim-tree/nvim-web-devicons" },
  { src = gh "nvim-lua/plenary.nvim" },

  { src = gh "nvim-treesitter/nvim-treesitter" },
  { src = gh "numToStr/Comment.nvim" },
  { src = gh "JoosepAlviste/nvim-ts-context-commentstring" },
  { src = gh "folke/snacks.nvim" },
  { src = gh "lewis6991/gitsigns.nvim" },
  { src = gh "folke/which-key.nvim" },

  { src = gh "mason-org/mason.nvim" },
  { src = gh "mfussenegger/nvim-lint" },
  { src = gh "mfussenegger/nvim-dap" },
  { src = gh "rcarriga/nvim-dap-ui" },
  { src = gh "nvim-neotest/nvim-nio" },
  { src = gh "theHamsta/nvim-dap-virtual-text" },
  { src = gh "jay-babu/mason-nvim-dap.nvim" },
  { src = gh "neovim/nvim-lspconfig" },
  { src = gh "stevearc/conform.nvim" },
  { src = gh "saghen/blink.cmp", version = "v1" },
  { src = gh "rafamadriz/friendly-snippets" },

  { src = gh "nvim-mini/mini.nvim" },
  { src = gh "folke/persistence.nvim" },
  { src = gh "MagicDuck/grug-far.nvim" },

  { src = gh "amrbashir/nvim-docs-view" },
  { src = gh "3rd/diagram.nvim" },
  { src = gh "OXY2DEV/markview.nvim" },
  { src = gh "vuki656/package-info.nvim" },
  { src = gh "MunifTanjim/nui.nvim" },

  { src = gh "mrcjkb/rustaceanvim", version = vim.version.range "6" },
  { src = gh "saecki/crates.nvim" },
  { src = gh "windwp/nvim-ts-autotag" },
  { src = gh "dsznajder/vscode-es7-javascript-react-snippets" },
  { src = gh "lmilojevicc/herdr-splits.nvim" },
}

local ok, err = pcall(vim.pack.add, M.specs, { load = true, confirm = false })
if not ok then
  vim.schedule(function()
    vim.notify("vim.pack.add failed: " .. err, vim.log.levels.ERROR)
  end)
end

return M
