if vim.env.HERDR_ENV ~= "1" then
  return
end

local ok, herdr_splits = pcall(require, "herdr-splits")
if not ok then
  return
end

herdr_splits.setup({
  -- Optional configuration defaults can be adjusted here
})

-- Auto-ensure the herdr-side plugin is installed/enabled in the current session
local function ensure_herdr_plugin()
  local output = vim.fn.system("herdr plugin list --json")
  local decode_ok, data = pcall(vim.json.decode, output)
  local is_installed = false
  if decode_ok and data and data.result and data.result.plugins then
    for _, plugin in ipairs(data.result.plugins) do
      if plugin.plugin_id == "herdr-splits" then
        is_installed = true
        break
      end
    end
  end

  if not is_installed then
    vim.system({ "herdr", "plugin", "install", "lmilojevicc/herdr-splits.nvim", "--yes" }, {}, function()
      vim.system({ "herdr", "server", "reload-config" }, {})
    end)
  end
end

-- Run checkhealth/ensure asynchronously to prevent blocking startup
vim.schedule(ensure_herdr_plugin)
