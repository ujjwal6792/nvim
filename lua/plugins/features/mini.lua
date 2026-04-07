return {
  "nvim-mini/mini.nvim",
  lazy = false,
  version = "*",
  config = function()
    require("mini.ai").setup {
      n_lines = 1000,
    }
    -- require("mini.animate").setup()
    require("mini.bracketed").setup()
    require("mini.move").setup {
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = "<M-a>",
        right = "<M-d>",
        down = "<M-s>",
        up = "<M-w>",

        -- Move current line in Normal mode
        line_left = "<M-a>",
        line_right = "<M-d>",
        line_down = "<M-s>",
        line_up = "<M-w>",
      },
    }
  end,
}
