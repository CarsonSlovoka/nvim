local bookmark = {}

bookmark.table = {
  { name = "HOME", path = "$HOME", row=nil },
  { name = "Config", path = "~/.config/nvim/init.lua", row=1 },
  { name = "Config row 1 row 5", path = "~/.config/nvim/init.lua", row=30, col=5},
}

-- 動態加載外部設定檔
local function load_external_bookmarks(file_path)
  -- 使用 pcall 防止加載外部檔案時出錯
  local ok, external_bookmarks = pcall(dofile, file_path)
  if not ok or type(external_bookmarks) ~= "table" then
    vim.notify("Failed to load bookmarks from " .. file_path, vim.log.levels.ERROR)
    return
  end

  -- 合併外部書籤
  for _, bk in ipairs(external_bookmarks) do
    table.insert(bookmark.table, bk)
  end
end

-- 在初始化時嘗試加載外部書籤 (例如: bookmarks.lua)
local external_file_path = vim.fn.stdpath("config") .. "/bookmark.lua"
load_external_bookmarks(external_file_path)

-- 使用 telescope.nvim 顯示書籤列表
function bookmark.show()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  -- 初始化書籤數據
  local entries = {}
  for _, bk in ipairs(bookmark.table) do
    -- 如果有行號，將其顯示在書籤列表中
    local display = bk.row and
      string.format("%s | %s (row: %d)", bk.name, bk.path, bk.row) or
      string.format("%s | %s", bk.name, bk.path)
    table.insert(entries, { display = display, path = bk.path, row = bk.row, col=bk.col })
  end

  -- 定義 Telescope 的 pickers
  pickers.new({}, {
    prompt_title = "書籤列表",
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      -- 選擇書籤時的行為
      actions.select_default:replace(function()
        actions.close(_)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          local path = selection.value.path:gsub("^~", os.getenv("HOME"))
          local row = selection.value.row
          local col = selection.value.col

          -- 打開檔案並跳轉到行號（若行號存在）
          vim.cmd("edit " .. path)
          if row then
            if col then
              vim.fn.cursor(row, col)
            else
              vim.fn.cursor(row, 0)
            end
          end
        else
          vim.api.nvim_echo({ { "無效的選擇，請重試！", "ErrorMsg" } }, false, {})
        end
      end)

      -- 可選：映射退出快捷鍵
      map("i", "<esc>", actions.close)
      return true
    end,
  }):find()
end

return bookmark
