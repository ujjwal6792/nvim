local ok, markdown = pcall(require, "configs.markdown")
if ok then
  markdown.setup(0)
end
