local bookmark = {}
bookmark.table = {} -- 書籤內容
bookmark.config = {
  preview_number_lines = 10
}
local bookmark_dir = vim.fn.stdpath("config") .. "/bookmarks" -- 書籤目錄
local default_bookmark_file = "default.lua"                   -- 預設書籤檔案
local current_bookmark_file = default_bookmark_file           -- 當前使用的書籤檔案
local bookmark_db_path = bookmark_dir .. "/" .. current_bookmark_file

-- 確保書籤目錄和預設檔案存在
local function ensure_dir_and_file_exists()
  -- 創建 bookmarks 目錄
  if vim.fn.isdirectory(bookmark_dir) == 0 then
    vim.fn.mkdir(bookmark_dir, "p")
    vim.notify("[telescope_bookmark] 初始化書籤目錄: " .. bookmark_dir, vim.log.levels.INFO)
  end

  -- 檢查並創建預設書籤檔案
  local default_path = bookmark_dir .. "/" .. default_bookmark_file
  local file = io.open(default_path, "r")
  if file then
    file:close()
    return
  end

  file = io.open(default_path, "w")
  if not file then
    vim.notify("無法創建檔案: " .. default_path, vim.log.levels.ERROR)
    return
  end

  -- 填入一些預設的內容
  file:write([[return {
  { name = "nvim config", path = vim.fn.stdpath("config") },
  { name = "bookmark config dir", path = vim.fn.stdpath("config") .. "/bookmarks" },
}]])
  file:close()
  vim.notify("[telescope_bookmark] 初始化預設書籤檔案: " .. default_path, vim.log.levels.INFO)
end

ensure_dir_and_file_exists()


-- 動態加載外部設定檔
local function load_external_bookmarks(file_path)
  -- 使用 pcall 防止加載外部檔案出錯
  local ok, external_bookmarks = pcall(dofile, file_path)
  if not ok or type(external_bookmarks) ~= "table" then
    vim.notify("Failed to load bookmarks from " .. file_path, vim.log.levels.ERROR)
    return
  end

  -- 清空當前表並合併新數據
  bookmark.table = {}
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

  file:write("return {\n")
  for _, bk in ipairs(bookmark.table) do
    local row = bk.row and tostring(bk.row) or "nil"
    local col = bk.col and tostring(bk.col) or "nil"
    local atime = bk.atime or os.time()
    local formatted_atime = type(atime) == "number" and os.date("%Y/%m/%d %H:%M:%S", atime) or atime -- 保存的時間，用數字不太好觀察
    file:write(string.format("  { name = %q, path = %q, row = %s, col = %s, atime = %q },\n",
      bk.name, bk.path, row, col, formatted_atime))
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
--- @param row number|nil 行號
--- @param col number|nil 列號
--- @param opts { force: boolean }
--- @return boolean
function bookmark.add(name, path, row, col, opts)
  row = row or nil
  col = col or nil
  opts = opts or {}

  for i, item in ipairs(bookmark.table) do
    if item.name == name then
      if not opts.force then
        vim.notify("❌ 此書籤名稱已存在: " .. name, vim.log.levels.ERROR)
        return false
      else
        -- force 下將已存在的刪除，之後重加
        table.remove(bookmark.table, i)
        break
      end
    end
  end

  table.insert(bookmark.table, {
    name = name,
    path = path,
    row = row,
    col = col,
    atime = os.time(), -- 訪問時間
  })
  return true
end

--- 更新書籤, 如果要永久保存, 請自行再呼叫save的方法
function bookmark.update(name, opts)
  opts = opts or {}
  -- if #opts == 0 then -- ipairs也就是opts有序的才能這樣用
  if next(opts) == nil then -- 對於無序的table，可以用next來確認是否為空
    return
  end

  for i, item in ipairs(bookmark.table) do
    if item.name == name then
      bookmark.table[i].atime = opts.atime or os.time()
      return
    end
  end
end

--- 切換書籤檔案
function bookmark.use_bookmark_file(filename)
  local new_path = bookmark_dir .. "/" .. filename
  if vim.fn.filereadable(new_path) == 0 then
    vim.notify("書籤檔案不存在: " .. new_path, vim.log.levels.ERROR)
    return
  end

  current_bookmark_file = filename
  bookmark_db_path = new_path
  load_external_bookmarks(bookmark_db_path)
  vim.notify("已切換至書籤檔案: " .. filename, vim.log.levels.INFO)
end

-- 初始化時加載預設書籤
load_external_bookmarks(bookmark_db_path)

-- 使用 telescope.nvim 顯示書籤列表
function bookmark.show()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")

  local entries = {}
  local name_width = 0
  local path_width = 0
  for _, bk in ipairs(bookmark.table) do
    if #bk.name > name_width then name_width = #bk.name end
    if #bk.path > path_width then path_width = #bk.path end
  end
  path_width = math.min(path_width, 99)

  -- 先對table進行排序，如此就可以不需要之後再排
  table.sort(bookmark.table, function(a, b)
    local function getComparableTime(t)
      if not t then return 0 end
      -- 如果是數字，直接返回
      if type(t) == "number" then return t end

      -- -- 如果是字串，嘗試解析為時間戳
      if type(t) == "string" then
        -- 假設格式是 "YYYY/MM/DD HH:MM:SS"
        local pattern = "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, min, sec = t:match(pattern)
        if year then
          return os.time({
            year = tonumber(year) or 0,
            month = tonumber(month) or 0,
            day = tonumber(day) or 0,
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec)
          })
        end
      end
      return 0
    end
    return getComparableTime(a.atime) > getComparableTime(b.atime)
  end)

  for _, bk in ipairs(bookmark.table) do
    local display = string.format( -- %-ns | %-ns -- name, path
      "%-" .. name_width .. "s" .. -- 類麼`%-5s` 其中-表示左對齊
      " | " ..
      "%-" .. path_width .. "s",
      bk.name,
      bk.path
    )
    table.insert(entries,
      {
        display = display, -- 呈現的內容

        -- 之後可以給其他自定義的屬性
        name = bk.name,
        path = bk.path,
        row = bk.row,
        col = bk.col,
        atime = bk.atime
      })
  end

  -- 定義 Telescope 的 pickers
  pickers.new({}, {
    prompt_title = "書籤列表 (" .. current_bookmark_file .. ")",

    -- finder定義: 通常是將自定義的table傳入
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return { -- 此為preview的function參數entry內容
          value = entry,
          display = entry.display,
          ordinal = entry.display
        }
      end,
    },

    -- 排序定義
    sorter = conf.generic_sorter({}),

    -- preview視窗(可選，如果有定義就會出現)
    -- preview要呈的內容是什麼都無所謂，選取的實際觸發內容定義在: attach_mappings
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local filepath = entry.value.path:gsub("^~", os.getenv("HOME")) -- 處理跳轉路徑
        local row = entry.value.row
        local col = entry.value.col

        if filepath and vim.fn.filereadable(filepath) == 1 then
          local target_row = row or 1 -- 預設為列號 1
          -- preview範圍: 上下: bookmark.config.preview_number_lines 列
          local start_row = math.max(target_row - bookmark.config.preview_number_lines, 1)
          local end_row = target_row + bookmark.config.preview_number_lines

          --- lines header + preview_lines
          local lines = {}
          local f = io.open(filepath, "r")
          if f then
            local current_line = 1
            for line in f:lines() do
              if current_line >= start_row and current_line <= end_row then
                table.insert(lines, line)
              end
              if current_line > end_row then break end
              current_line = current_line + 1
            end
            f:close()
          end

          --[[ 也可以考慮一次讀，速度會比較快，但是會消耗比較多的記憶體
          local lines = vim.fn.readfile(filepath, "", end_row)
          lines = vim.list_slice(lines, start_row, end_row)
          --]]

          -- 設置行內容到 Telescope 的預覽窗口
          if #lines == 0 then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "無法讀取指定範圍的文件內容。" })
          else
            -- 添加附加訊息到一開始
            local context_header = {
              string.rep("-", 40),
              filepath,
              "row: " .. (row or "nil") .. " col: " .. (col or "nil"), --  -- 如果是透過指令加入，不會nil發生，但如果是手動編輯~/.config/nvim/bookmark.lua檔案，就有可能會發生失誤，因此這時候用nil呈現
              string.rep("-", 40)
            }
            local numbered_lines = {}
            for i, line in ipairs(lines) do
              local line_num = start_row + i - 1
              local prefix = line_num == target_row and string.format("%4d 👉 | ", line_num) or
                  string.format("%4d    | ", line_num)
              table.insert(numbered_lines, prefix .. " " .. line)
            end
            -- 合併所有內容
            local final_content = vim.list_extend(              -- list_extend只直接改變第一個參數的數值
              vim.tbl_deep_extend("force", {}, context_header), -- 為了讓list_extend後不會異動原始的context_header，所以複製一份
              numbered_lines
            )

            vim.api.nvim_buf_set_lines(self.state.bufnr, -- 設定緩衝區的內容
              0,                                         -- start 開始的列, 首列為0, -1可以自動接續下去寫
              -1,                                        -- end 結束的列, 而用-1將會自己依據給定的文本
              false,                                     -- false為寬鬆如果超過start, end不會觸發錯誤
              final_content
            )

            -- 設置語法高亮為 markdown
            --[[ nvim_buf_add_highlight 這種highlight是針對單行的方式，例如: 搜尋關鍵字等等
            -- https://neovim.io/doc/user/api.html#nvim_buf_add_highlight()
            vim.api.nvim_buf_add_highlight(self.state.bufnr,
              -1, -- namespace ID, -1可以自動生成一個新的命名空間
              "IncSearch", -- hl_group 可以由 :highlight 得知
              0, -- line
              0, -- col_start
              -1 -- col_end
            )
            --]]

            -- 語法高亮設定
            local filetype = vim.filetype.match({ filename = filepath }) or "text" -- 如果找不到匹配就用text
            vim.api.nvim_buf_set_option(self.state.bufnr, 'syntax', filetype)

            -- 最後再調整context_header的高亮顯示(覆蓋)
            -- 用extmark來設定附加訊息的一些顏色設定
            -- 先將所有heaer的範圍都設定成: Comment, 再設定line 1-2 (列行資訊): @label
            local ns_id = vim.api.nvim_create_namespace('custom_highlight')
            vim.api.nvim_buf_set_extmark(
              self.state.bufnr,
              ns_id, -- 不能設為-1
              0,     -- line
              0,     -- cik
              {
                end_row = #context_header,
                -- end_col = -1, -- 不能設定為-1
                -- hl_group = '' -- 如果hl_group沒有突顯, 會先用syntax的突顯
                hl_group = 'Comment' --  使用 :highlight 查看, Title. 也可以用:Telescope highlights來找想要的
              }
            )
            vim.api.nvim_buf_set_extmark(self.state.bufnr, ns_id, 1, 0, { end_row = 2, hl_group = '@label' })

            -- nvim_buf_set_extmark 如果要做markdown的code-block突顯，就會需要用到此技巧: https://neovim.io/doc/user/api.html#nvim_buf_set_extmark()
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

    -- 修改layout放法: 預設preview在右邊，如果書籤內容太長會被preview影響
    --[[ -- 預設的layout_config已經很好了，不需要再特別調整
    layout_config = {
      preview_cutoff = 0, -- 窗口切分點，0 表示總是顯示 preview
      horizontal = { -- 使用 horizontal 布局
        preview_width = 0.5, -- 預覽窗口佔左右分佈的空間比重 (小於 1 的數字)
      },
      vertical = { -- 如果想改設為 vertical 布局
        preview_height = 0.5, -- 預覽窗口佔上下分佈空間高度比重
      },
    },
    ]]
    -- layout_strategy = "vertical", -- 規定窗口佈局為水平 -- 不再定義，用原始的定義

    -- 快捷鍵相關定義
    attach_mappings = function(_, map)
      -- 選擇書籤時的行為<Enter>鍵
      actions.select_default:replace(function()
        actions.close(_)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          local bk = selection.value
          print("select " .. bk.name)
          bookmark.update(bk.name, { atime = os.time() })

          -- 打開檔案並跳轉到行號（若行號存在）
          vim.cmd("edit " .. bk.path:gsub("^~", os.getenv("HOME"))) -- 選中就用edit開啟, 如果用~將其用HOME來展開
          -- 移動cursor到指定的row, col
          vim.fn.cursor(bk.row or 0, bk.col + 1)
        else
          vim.api.nvim_echo({ { "無效的選擇，請重試！", "ErrorMsg" } }, false, {})
        end
      end)

      -- 按下 d 觸發, 刪除該bookmark
      map("n", "d", function(prompt_bufnr)
        local selection = action_state.get_selected_entry() -- 獲取當前選中的項目
        if selection then
          -- print(vim.inspect(selection.value))
          bookmark.delete(selection.value.name, { verbose = true })
          bookmark.save {}
          actions.close(prompt_bufnr)
          bookmark.show()
        end
      end)


      -- 可選：定義其他熱鍵
      -- map("i", "<esc>", actions.close) <-- 這樣不能選模式

      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command("BkUse", function(opts)
  if #opts.args == 0 then
    vim.notify("請提供書籤檔案名稱，例如: BkUse work.lua", vim.log.levels.ERROR)
    return
  end
  local filename = opts.args
  if not filename:match("%.lua$") then
    filename = filename .. ".lua"
  end
  bookmark.use_bookmark_file(filename)
end, {
  nargs = 1,
  complete = function(arg_lead)
    -- 獲取 bookmarks 目錄下的所有 .lua 檔案
    local bk_dir = vim.fn.stdpath("config") .. "/bookmarks"
    local files = {}
    vim.fn.readdir(bk_dir,
      function(entry)
        if entry:match("%.lua$") then
          table.insert(files, entry)
        end
      end
    )

    -- 如果目錄不存在或沒有 .lua 檔案，返回空表
    if not files then
      return {}
    end

    if #arg_lead == 0 then
      return files
    end

    -- 過濾出以當前輸入開頭的檔案名
    local matches = {}
    for _, file in ipairs(files) do
      if file:find("^" .. arg_lead) then
        table.insert(matches, file)
      end
    end

    return matches
  end,
})

return bookmark
