local ok, which_key = pcall(require, "which-key")
if not ok then
  return
end

which_key.setup {
  win = {
    -- Prevent which-key from falling back to solid backgrounds
    no_overlap = true,
    padding = { 1, 2 },
    title = true,
    title_pos = "center",
    -- Link highlights straight to your transparent NormalFloat rules
    wo = {
      winblend = 0,
      winhighlight = "Normal:Normal,NormalFloat:Normal,FloatBorder:FloatBorder",
    },
  },
}
