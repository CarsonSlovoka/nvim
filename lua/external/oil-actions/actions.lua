local oil = require("oil")


---@class OilMenuItem
---@field label string
---@field callback? fun(path: string) -- 有 callback 就是葉節點（實際動作）
---@field children? OilMenuItem[]     -- 有 children 就是子選單
---@field desc? string                -- 可選說明（未來可給 format_item 用）

---@class OilFileAction
---@field label string                -- 選單顯示文字
---@field callback fun(path: string)  -- 實際執行函式，path 已是完整絕對路徑

---@type table<string, OilFileAction[]>
local actions_by_ext = {
  -- 依據檔案附檔名來判斷
  zip = require("external.oil-actions.zip"),
  lua = require("external.oil-actions.lua"),
  py = require("external.oil-actions.py"),
  ttf = require("external.oil-actions.ttf"),
  otf = require("external.oil-actions.ttf"), -- 同ttf
}

---取得目前游標下的完整路徑（僅在 oil buffer 有效）
---@return string|nil path, string|nil err
local function get_cursor_path()
  local entry = oil.get_cursor_entry()
  if not entry then
    return nil, "no entry under cursor"
  end
  if entry.type ~= "file" then
    return nil, ("not a regular file (type = %s)"):format(entry.type)
  end
  local dir = oil.get_current_dir()
  if not dir then
    return nil, "cannot get current oil directory"
  end
  -- oil.get_current_dir() 回傳的路徑已帶尾端 /
  return dir .. entry.name
end

---顯示一層選單（遞迴）
---@param items OilMenuItem[]
---@param path string
---@param title string
---@param parent_items? OilMenuItem[]   -- 用來實作「返回」
---@param parent_title? string
local function show_menu(items, path, title, parent_items, parent_title)
  -- 複製一份，避免污染原始表
  local display = {}
  local map = {} -- idx → 真正的 OilMenuItem 或特殊標記

  for _, item in ipairs(items) do
    display[#display + 1] = item.label
    map[#display] = item
  end

  -- 非根層才在最後一個項目加「返回」
  if parent_items then
    display[#display + 1] = "← Back"
    map[#display] = { __back = true }
  end

  vim.ui.select(display, {
    prompt = title,
    kind = "oil_nested_menu",
  }, function(_, idx)
    if not idx then return end

    local chosen = map[idx]
    if not chosen then return end

    -- 返回上層
    if chosen.__back then
      if parent_items then
        show_menu(parent_items, path, parent_title or "Actions", nil, nil)
      end
      return
    end

    -- == 若該節點直接有callback屬性就直接執行, 否則看看是否具備子選單 ==

    -- 子節點 → 執行
    if chosen.callback then
      chosen.callback(path)
      return
    end

    -- 有子選單 → 進入下一層
    if chosen.children and #chosen.children > 0 then
      show_menu(
        chosen.children,
        path,
        chosen.label, -- 下一層的 title
        items,        -- 目前這層作為 parent
        title         -- 目前這層的 title（給返回用）
      )
    end
  end)
end

---主入口：依副檔名彈出對應選單
local function file_actions()
  local path, err = get_cursor_path()
  if not path then
    vim.notify(err or "unknown error", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")
  local ext = (name:match("%.([^%.]+)$") or ""):lower()

  local root_items = actions_by_ext[ext]
  if not root_items or #root_items == 0 then
    vim.notify(("No actions defined for .%s"):format(ext), vim.log.levels.INFO)
    return
  end

  show_menu(root_items, path, ("Actions · %s"):format(name))
end

return {
  file_actions = file_actions,
  -- 方便外部擴充
  actions_by_ext = actions_by_ext,
}
