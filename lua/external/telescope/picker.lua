local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

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
  -- 確保預覽器啟用
  opts.previewer = previewers.vim_buffer_cat.new(opts) -- 新增預覽視窗
  -- opts.layout_config = {
  --   width = 0.9,
  --   height = 0.9,
  --   preview_width = 0.5,     -- 預覽視窗佔一半寬度
  --   prompt_position = "top", -- 提示列在頂部
  -- }
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
