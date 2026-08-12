local oil = require("oil")

---@class OilFileAction
---@field label string                -- 選單顯示文字
---@field callback fun(path: string)  -- 實際執行函式，path 已是完整絕對路徑

---@type table<string, OilFileAction[]>
local actions_by_ext = {
  -- 依據檔案附檔名來判斷
  zip = require("external.oil-actions.zip"),
  lua = require("external.oil-actions.lua"),
  py = require("external.oil-actions.py"),
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

---主入口：依副檔名彈出對應選單
local function file_actions()
  local path, err = get_cursor_path()
  if not path then
    vim.notify(err or "unknown error", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")
  local ext = (name:match("%.([^%.]+)$") or ""):lower()

  local actions = actions_by_ext[ext]
  if not actions or #actions == 0 then
    vim.notify(("No actions defined for .%s"):format(ext), vim.log.levels.INFO)
    return
  end

  -- 只做一次 table 轉換，避免在 select 內反覆配置
  local labels = {}
  for i, act in ipairs(actions) do
    labels[i] = act.label
  end

  vim.ui.select(labels, {
    prompt = ("Actions for %s"):format(name),
    kind = "oil_file_action",
  }, function(_, idx)
    if idx and actions[idx] then
      actions[idx].callback(path)
    end
  end)
end

return {
  file_actions = file_actions,
  -- 方便外部擴充
  actions_by_ext = actions_by_ext,
}
