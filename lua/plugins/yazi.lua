local ok, yazi = pcall(require, "yazi")
if not ok then
  return
end

yazi.setup {
  floating_window_scaling_factor = 0.75,
  open_for_directories = false,
  keymaps = {
    show_help = "<f1>",
  },
}
