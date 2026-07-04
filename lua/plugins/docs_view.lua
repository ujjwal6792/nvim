local ok, docs_view = pcall(require, "docs-view")
if not ok then
  return
end

docs_view.setup {
  position = "right",
  width = 60,
}
