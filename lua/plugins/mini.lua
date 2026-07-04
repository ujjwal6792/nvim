local ok_ai, mini_ai = pcall(require, "mini.ai")
if ok_ai then
  mini_ai.setup { n_lines = 1000 }
end

local ok_bracketed, mini_bracketed = pcall(require, "mini.bracketed")
if ok_bracketed then
  mini_bracketed.setup()
end

local ok_move, mini_move = pcall(require, "mini.move")
if ok_move then
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

local ok_statusline, mini_statusline = pcall(require, "mini.statusline")
if ok_statusline then
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
