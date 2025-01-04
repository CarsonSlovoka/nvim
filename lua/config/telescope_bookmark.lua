local bookmark = {}
local bookmark_db_path = vim.fn.stdpath("config") .. "/bookmark.lua"

bookmark.table = {
  --[[
  { name = "HOME", path = "$HOME", row = nil },
  { name = "Config", path = "~/.config/nvim/init.lua", row = 1 },
  { name = "Config row 1 row 5", path = "~/.config/nvim/init.lua", row = 30, col = 5 },
  --]]
}

bookmark.config = {
  preview_number_lines = 10
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

--- @param name string
--- @param opts table
function bookmark.delete(name, opts)
  for i, item in ipairs(bookmark.table) do
    if item.name == name then
      table.remove(bookmark.table, i)
      if opts.verbose then
        vim.notify("✅已成功刪除書籤: " .. vim.inspect(item), vim.log.levels.INFO)
      end
      break
    end
  end
end

--- 將書籤保存於實體檔案
--- @param opts {verbose: boolean}
function bookmark.save(opts)
  local file, err = io.open(bookmark_db_path, "w")
  if not file then
    vim.notify("Failed to open " .. bookmark_db_path .. " for writing:\n" .. err, vim.log.levels.ERROR)
    return
  end

  -- 開始寫入檔案的表頭及內容
  file:write("return {\n")

  for _, bk in ipairs(bookmark.table) do
    local row = bk.row and tostring(bk.row) or "nil"
    local col = bk.col and tostring(bk.col) or "nil"

    file:write(string.format("  { name = %q, path = %q, row = %s, col = %s },\n",
      bk.name, bk.path, row, col))
  end

  file:write("}\n")
  file:close()

  if opts.verbose then
    vim.notify("Bookmarks saved to " .. bookmark_db_path, vim.log.levels.INFO)
  end
end

--- 添加一個書籤
--- @param name string 書籤名稱
--- @param path string 文件路徑
--- @param row number 行號
--- @param col number 列號
function bookmark.add(name, path, row, col)
  row = row or nil
  col = col or nil

  table.insert(bookmark.table, {
    name = name,
    path = path,
    row = row,
    col = col,
  })
end

-- 在初始化時嘗試加載外部書籤 (例如: bookmarks.lua)
load_external_bookmarks(bookmark_db_path)

-- 使用 telescope.nvim 顯示書籤列表
function bookmark.show()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  -- local path_to_display = require("plenary.path").new

  -- 初始化書籤數據
  local entries = {}
  for _, bk in ipairs(bookmark.table) do
    -- 如果有行號，將其顯示在書籤列表中
    -- 有row就會有col
    local display = bk.row and
      string.format("%s | %s (row: %d) (col: %d)", bk.name, bk.path, bk.row, bk.col) or
      string.format("%s | %s", bk.name, bk.path)
    table.insert(entries, {
      display = display, -- 呈現的內容
      -- 以下可以給其它的屬性
      name = bk.name,
      path = bk.path,
      row = bk.row, col = bk.col
    })
  end

  -- 定義 Telescope 的 pickers
  pickers.new({}, {
    prompt_title = "書籤列表",

    -- finder定義: 通常是將自定義的table傳入
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return { -- 此為preview的function參數entry內容
          value = entry,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    },

    -- 排序定義
    sorter = conf.generic_sorter({}),

    -- preview視窗(可選，如果有定義就會出現)
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local filepath = entry.value.path:gsub("^~", os.getenv("HOME")) -- 處理跳轉路徑
        local row = entry.value.row

        -- 如果文件路徑有效，顯示內容
        if filepath and vim.fn.filereadable(filepath) == 1 then
          local lines = {}
          local target_row = row or 1 -- 預設為行號 1
          -- preview範圍: 上下: bookmark.config.preview_number_lines 行
          local start_row = math.max(target_row - bookmark.config.preview_number_lines, 1)
          local end_row = target_row + bookmark.config.preview_number_lines

          -- 運用 Neovim 內建的方法讀取指定範圍的行
          local f = io.open(filepath, "r")
          if f then
            local current_line = 1
            for line in f:lines() do
              if current_line >= start_row and current_line <= end_row then
                table.insert(lines, line)
              end
              if current_line > end_row then
                break
              end
              current_line = current_line + 1
            end
            f:close()
          end

          -- 設置行內容到 Telescope 的預覽窗口
          if #lines > 0 then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            -- 加入高亮邏輯
            if row then
              local hl_row = row - start_row -- 不能直接放原本的列號，因為呈現的文本不是所有，只有部份內容，所以列號也要修正
              vim.notify("hl_row" .. hl_row, vim.log.levels.INFO)
              vim.api.nvim_buf_add_highlight(self.state.bufnr, -1,
                "Visual",
                hl_row, -- row
                0, -- col-start
                -1 -- col-end
              )
            end
          else
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "無法讀取指定範圍的文件內容。" })
          end
        elseif vim.fn.isdirectory(filepath) == 1 then
          local dir_content = vim.fn.readdir(filepath)
          if #dir_content > 0 then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "目錄內容：" })
            vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, false, dir_content)
          else
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "此目錄為空：" .. filepath })
          end
        else
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "文件無法讀取: " .. filepath })
        end
      end,
    }),

    -- 快捷鍵相關定義
    attach_mappings = function(_, map)
      -- 選擇書籤時的行為<Enter>鍵
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

      -- 按下 d 觸發, 刪除該bookmark
      map("n", "d", function(prompt_bufnr)
        local selection = action_state.get_selected_entry() -- 獲取當前選中的項目
        if selection then
          -- print(vim.inspect(selection.value)) -- vim.inspect可以將Lua的值結構化輸出，適合用來將複雜結構轉為方便人讀的字符串
          bookmark.delete(selection.value.name, { verbose = true })
          bookmark.save {} -- 保存
          -- 重啟
          actions.close(prompt_bufnr) -- 關閉 Telescope
          bookmark.show()
        end
      end)

      -- 可選：映射退出快捷鍵 <-- 這樣不能選模式
      -- map("i", "<esc>", actions.close)
      return true
    end,
  })     :find()
end

return bookmark
