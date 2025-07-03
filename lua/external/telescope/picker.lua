local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local M = {}

local function get_all_files()
  local files = {}                            -- 裡面的元素可以是單純字串或者table都可以，
  local cwd = vim.fn.getcwd():gsub("\\", "/") -- 標準化為正斜線
  local function scandir(directory)
    local handle = vim.uv.fs_scandir(directory)
    if not handle then return end
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end
      local path = (directory .. "/" .. name):gsub("\\", "/") -- 標準化路徑
      if type == "file" then
        local relative_path = path:sub(#cwd + 2)
        table.insert(files, {
          display = relative_path, -- 要顯示在清單中的內容
          abspath = path,
        })
      elseif type == "directory" then
        scandir(path)
      end
    end
  end
  scandir(vim.fn.getcwd())
  return files
end


local function sanitize_lines(lines)
  local sanitized = {}
  for _, line in ipairs(lines) do
    -- 移除換行符
    line = line:gsub("[\n\r]", "")
    table.insert(sanitized, line)
  end
  return sanitized
end

---@param opts table
---@param callback function
function M.get_file(opts, callback)
  opts = opts or {}
  -- opts.previewer = previewers.vim_buffer_cat.new(opts) -- 新增預覽視窗 (由於將entry由原本的每個元素為字串，改成table, 所以不可用了，要自定)
  opts.previewer = previewers.new_buffer_previewer({
    title = "File Preview",
    define_preview = function(self, entry, status)
      local path = entry.path or entry.value.abspath
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})

      local lines = vim.fn.readfile(path, "", 100) -- 限制讀取前 100 行
      lines = sanitize_lines(lines)                -- 清理行內容, 避免某些二進位文件會有問題(該line有new line會讓nvim_buf_set_lines錯誤)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end,
  })

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
      entry_maker = function(entry) -- 在results的每一個元素非字串，而是table時，要新增這個
        return {
          value = entry,
          -- display, ordinal都要有
          display = entry.display,
          ordinal = entry.display
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        -- print(vim.inspect(selection))
        actions.close(prompt_bufnr)
        -- callback(selection and selection[1] or nil)
        callback(selection.value.abspath)
      end)
      return true
    end,
  }):find()

  return true
end

return M
