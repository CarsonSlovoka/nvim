local bookmarks_file = vim.fn.stdpath('config') .. '/bookmarks.json'

-- 確保書籤文件存在
local function ensure_bookmarks_file()
  if vim.fn.filereadable(bookmarks_file) == 0 then
    local file = io.open(bookmarks_file, "w")
    file:write("{}")
    file:close()
  end
end

-- 讀取書籤文件
local function load_bookmarks()
  ensure_bookmarks_file()
  local file = io.open(bookmarks_file, "r")
  local content = file:read("*a")
  file:close()
  return vim.fn.json_decode(content) or {}
end

-- 保存書籤文件
local function save_bookmarks(bookmarks)
  local file = io.open(bookmarks_file, "w")
  file:write(vim.fn.json_encode(bookmarks))
  file:close()
end

-- 添加書籤
local function add_bookmark(name, path)
  local bookmarks = load_bookmarks()
  bookmarks[name] = path
  save_bookmarks(bookmarks)
end

-- 刪除書籤
local function remove_bookmark(name)
  local bookmarks = load_bookmarks()
  bookmarks[name] = nil
  save_bookmarks(bookmarks)
end

-- 重新命名書籤
local function rename_bookmark(old_name, new_name)
  local bookmarks = load_bookmarks()
  if bookmarks[old_name] then
    bookmarks[new_name] = bookmarks[old_name]
    bookmarks[old_name] = nil
    save_bookmarks(bookmarks)
  else
    vim.notify("Bookmark not found: " .. old_name, vim.log.levels.ERROR)
  end
end

-- 顯示書籤
local function list_bookmarks()
  local bookmarks = load_bookmarks()
  local items = {}
  for name, path in pairs(bookmarks) do
    table.insert(items, { name = name, path = path })
  end
  return items
end

return {
  add_bookmark = add_bookmark,
  remove_bookmark = remove_bookmark,
  rename_bookmark = rename_bookmark,
  list_bookmarks = list_bookmarks,
}
