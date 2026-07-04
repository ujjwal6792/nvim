local ok, comment = pcall(require, "Comment")
if not ok then
  return
end

local pre_hook
local ok_integration, integration = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
if ok_integration then
  pre_hook = integration.create_pre_hook()
end
comment.setup { pre_hook = pre_hook }
