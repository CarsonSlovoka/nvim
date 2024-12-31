local bookmark = {}

bookmark.table = {
  { name = "HOME", path = "$HOME" },
  { name = "Config", path = "~/.config/nvim/init.lua" },
}

-- 打開書籤的函數
local function open_bookmark(path)

  local stat = vim.loop.fs_stat(path) -- 檢查路徑狀態

  if stat and stat.type == "directory" then
    -- 如果 path 是一個目錄
    print(path .. "|" .. stat.type)
    vim.cmd("NvimTreeOpen " .. path)
  else
    -- 如果 path 是一個文件或無法判別
    vim.cmd("edit " .. path)
  end
end

function bookmark.add(name, path)
  table.insert(bookmark.table, { name = name, path = path })
end

function bookmark.deleteByIndex(index)
  table.remove(bookmark.table, index)
end

function bookmark.deleteByName(name)
  for i, item in ipairs(bookmark.table) do
    if item.name == name then
      table.remove(bookmark.table, i)
      break
    end
  end
end

function bookmark.show()
  -- 配置浮動窗口
  local buf = vim.api.nvim_create_buf(false, true) -- 創建新的緩衝區，且不列入 buffer 列表

  -- 計算最大長度
  local max_name_length = 0
  local max_path_length = 0

  for _, bk in ipairs(bookmark.table) do
    if #bk.name > max_name_length then
      max_name_length = #bk.name
    end
    if #bk.path > max_path_length then
      max_path_length = #bk.path
    end
  end

  -- 動態計算窗口寬度
  local width = max_name_length + max_path_length + 8 -- 包括數字索引+" | " 分隔符的額外固定部分
  local height = #bookmark.table + 2 -- 上下各留 1 行

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.min(width, vim.o.columns - 10), -- 限制寬度不超過屏幕寬度 - 10
    height = math.min(height, vim.o.lines - 4), -- 限制高度不超過屏幕高度 - 4
    row = math.floor((vim.o.lines - height) / 2), -- 垂直居中
    col = math.floor((vim.o.columns - width) / 2), -- 水平居中
    style = "minimal",
    border = "rounded",
  })

  -- 設置浮動窗口內容（列出所有書籤名稱）
  local lines = { "書籤列表： (打上數字後前往)" }
  for i, bk in ipairs(bookmark.table) do
    -- table.insert(lines, i .. ". " .. bk.name .. "|" .. bk.path) -- 可行但是很醜
    local padded_name = bk.name .. string.rep(" ", max_name_length - #bk.name) -- 填充空格
    table.insert(lines, i .. ". " .. padded_name .. " | " .. bk.path)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) -- 放入window內的文本內容

  -- 設置浮動窗口的鍵盤交互
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<Cmd>close<CR>", { noremap = true, silent = true })
  for i, bk in ipairs(bookmark.table) do
    -- 每個書籤綁定一個快捷鍵（數字選擇）
    vim.api.nvim_buf_set_keymap(buf, "n",
      tostring(i), -- 熱鍵為number
      "", -- 沒有實作，用callback來代替
      {
        noremap = true,
        silent = true,
        callback = function()
          vim.api.nvim_win_close(win, true) -- 關閉浮動窗口
          open_bookmark(bk.path) -- 打開選擇的書籤
        end,
      }
    )

    vim.api.nvim_buf_set_keymap(buf, "n",
      "d" .. tostring(i), -- d + 數字可以刪除該bookmark
      "",
      {
        noremap = true,
        silent = true,
        callback = function()
          bookmark.deleteByIndex(i)
          -- 重新刷新列表的方式為先關閉再開啟
          vim.api.nvim_win_close(0, true) -- <Cmd>close<CR>
          bookmark.show()
        end,
      }
    )
  end
end

return bookmark
