local telescope = require("telescope")
local picker = require("tasks-nvim.picker")

return telescope.register_extension({
  exports = {
    tasks = function(opts)
      picker.open(opts)
    end,
  },
})
