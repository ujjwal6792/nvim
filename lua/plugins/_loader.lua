-- Automatically requires every *.lua file in this directory (except itself)
local dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
for _, path in ipairs(vim.fn.glob(dir .. "/*.lua", false, true)) do
  local name = vim.fn.fnamemodify(path, ":t:r")
  if name ~= "_loader" then
    local mod = "plugins." .. name
    local ok, err = pcall(require, mod)
    if not ok then
      vim.schedule(function()
        vim.notify("[plugins] failed to load " .. mod .. ":\n" .. err, vim.log.levels.ERROR)
      end)
    end
  end
end
