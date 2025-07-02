local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}

local function get_all_files()
  local files = {}
  local function scandir(directory)
    local handle = vim.uv.fs_scandir(directory)
    if not handle then return end
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end
      local path = directory .. "/" .. name
      if type == "file" then
        table.insert(files, path)
      elseif type == "directory" then
        scandir(path)
      end
    end
  end
  scandir(vim.fn.getcwd())
  return files
end

---@param opts table
---@param callback function
function M.get_file(opts, callback)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = opts.title or "All Files in CWD",
    finder = finders.new_table {
      results = get_all_files(),
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- if selection then
        --   print("Selected file: " .. selection[1])
        -- end
        callback(selection[1])
      end)
      return true
    end,
  }):find()
end

return M
