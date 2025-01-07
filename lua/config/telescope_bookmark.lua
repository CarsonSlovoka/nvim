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

  -- 計算填充寬度
  local name_width = 0
  local path_width = 0
  for _, bk in ipairs(bookmark.table) do
    if #bk.name > name_width then
      name_width = #bk.name
    end
    if #bk.path > path_width then
      path_width = #bk.path
    end
  end
  for _, bk in ipairs(bookmark.table) do
    -- 如果有行號，將其顯示在書籤列表中
    -- 有row就會有col
    --[[ 不需要顯示不重要的資訊，可能會影響搜尋，將這些資訊放到preview呈現
    local display = bk.row and
      string.format("%s | %s (row: %d) (col: %d)", bk.name, bk.path, bk.row, bk.col) or
      string.format("%s | %s", bk.name, bk.path)
    --]]
    local display = string.format(
      "%-" .. name_width .. "s" .. -- 類麼`%-5s` 其中-表示左對齊
        " | " ..
        "%-" .. path_width .. "s",
      bk.name,
      bk.path -- 可能也會用到檔案路徑搜尋，所以還是給上
    )
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
    -- preview要呈的內容是什麼都無所謂，選取的實際觸發內容定義在: attach_mappings
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local filepath = entry.value.path:gsub("^~", os.getenv("HOME")) -- 處理跳轉路徑
        local row = entry.value.row
        local col = entry.value.col

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
          if #lines == 0 then
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "無法讀取指定範圍的文件內容。" })
          else
            -- 添加上下文信息
            local context_header = {
              string.rep("-", 40),
              filepath,
              "row: " .. (row or "nil") .. " col: " .. (col or "nil"), -- 如果是透過指令加入，不會nil發生，但如果是手動編輯~/.config/nvim/bookmark.lua檔案，就有可能會發生失誤，因此這時候用nil呈現
              string.rep("-", 40)
            }

            -- 在每行前添加行號
            local numbered_lines = {}
            for i, line in ipairs(lines) do
              local line_num = start_row + i - 1
              local prefix
              -- 高亮選中的行
              if line_num == target_row then
                prefix = string.format("%4d 👉 | ", line_num)
              else
                prefix = string.format("%4d    | ", line_num)
              end
              table.insert(numbered_lines, prefix .. " " .. line)
            end

            -- 合併所有內容
            local copy_context_header = vim.tbl_deep_extend("force", {}, context_header) -- 為了讓list_extend後不會異動原始的context_header，所以複製一份
            local final_content = vim.list_extend(copy_context_header, numbered_lines) -- list_extend只直接改變第一個參數的數值

            -- 設置預覽緩衝區的內容
            vim.api.nvim_buf_set_lines(self.state.bufnr,
              0, -- start 開始的列, 首列為0, -1可以自動接續下去寫
              -1, -- end 結束的列, 可以用此範例可以用2，而用-1將會自己依據給定的文本
              false, -- false為寬鬆如果超過start, end不會觸發錯誤
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

            -- 根據文件類型動態設置後續部分的語法高亮
            local file_extension = filepath:match("^.+(%..+)$")
            if file_extension then
              local filetype = vim.filetype.match({ filename = filepath }) or "text" -- 如果無法檢測則使用 "text"
              vim.api.nvim_buf_set_option(self.state.bufnr, 'syntax', filetype)
            else
              vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, 'text', #context_header, 0, -1)
            end

            -- 最後在調整context_header的部份用
            --[[ nvim_buf_set_extmark 如果要做markdown的code-block突顯，就會需要用到此技巧
              https://neovim.io/doc/user/api.html#nvim_buf_set_extmark()
            --]]
            -- 先都設定為Comment
            local ns_id = vim.api.nvim_create_namespace('custom_highlight')
            vim.api.nvim_buf_set_extmark(self.state.bufnr,
              ns_id, -- 不能設定為-1
              0, -- line
              0, -- col
              {
                end_row = #context_header,
                -- end_col = -1, -- 不能設定為-1
                -- hl_group = 'IncSearch', -- 使用 :highlight 查看, Title
                hl_group = 'Comment' -- 如果給的hl_group沒有突顯，會先用syntax的突顯
              }
            )

            -- 在將path調整為@label
            vim.api.nvim_buf_set_extmark(self.state.bufnr,
              ns_id,
              1,
              0, -- col
              {
                end_row = 2,
                hl_group = '@label' -- Title
              }
            )
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
    ]]--
    layout_strategy = "vertical", -- 規定窗口佈局為水平

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
