local ok, auto_session = pcall(require, "auto-session")
if not ok then
  return
end

local function restore_launch_cwd()
  local cwd = vim.g.launch_cwd or vim.uv.cwd()
  if not cwd or cwd == "" then
    return
  end

  vim.cmd("cd " .. vim.fn.fnameescape(cwd))
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
      end)
    end
  end

  vim.schedule(function()
    local ok_api, api = pcall(require, "nvim-tree.api")
    if ok_api then
      pcall(api.tree.change_root, cwd)
      pcall(api.tree.reload)
    end
    require("configs.buffers").keep_nvimtree_width()
  end)
end

auto_session.setup {
  auto_restore = false,
  auto_restore_enabled = false,
  close_filetypes_on_save = { "NvimTree", "terminal" },
  cwd_change_handling = false,
  suppressed_dirs = { "~/" },
  post_restore_cmds = {
    restore_launch_cwd,
    function()
      local cwd = vim.fn.getcwd()
      local cwd_prefix = vim.fn.fnamemodify(cwd, ":p")
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= "" and vim.bo[buf].buftype == "" then
            local abs_path = vim.fn.fnamemodify(name, ":p")
            if abs_path:sub(1, #cwd_prefix) ~= cwd_prefix then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end
    end,
  },
  no_restore_cmds = {
    function()
      restore_launch_cwd()
    end,
  },
  session_lens = {
    load_on_setup = true,
    previewer = false,
    mappings = {
      delete_session = { "i", "<C-D>" },
      alternate_session = { "i", "<C-S>" },
      copy_session = { "i", "<C-Y>" },
    },
    theme_conf = { border = true },
  },
}
