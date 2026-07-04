if #vim.api.nvim_list_uis() == 0 then
  return
end

local ok, image = pcall(require, "image")
if not ok then
  return
end

image.setup {
  backend = "kitty",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = true,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "markdown", "vimwiki" },
    },
    neorg = {
      enabled = true,
      clear_in_insert_mode = true,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "norg" },
    },
  },
  max_height_window_percentage = 50,
  kitty_method = "normal",
}
