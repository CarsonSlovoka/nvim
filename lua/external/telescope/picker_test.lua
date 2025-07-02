vim.api.nvim_create_user_command(
  "Test123",
  function()
    local picker = require("external.telescope.picker")
    picker.get_file({ title = "Test" }, function(select_item)
      print("aa ", select_item)
    end)
  end,
  { desc = "Test" }
)
