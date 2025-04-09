local M = {}

---@param s string
---@return table
function M.parse(s)
  local args = {}
  for arg in s:gmatch("%S+") do -- 用空白來拆分
    table.insert(args, arg)
  end
  local result = {
    params = {}, -- 存儲普通參數
    opts = {},   -- 存儲帶--的選項
  }

  for _, arg in ipairs(args) do
    if arg:match("^%-%-") then -- 開頭是--
      local key, val = arg:match("^%-%-([a-zA-Z0-9_]+)=([^%s]+)$")
      if key and val then
        result.opts[key] = val
      else
        -- 如果沒有 = 視為bool
        key = arg:match("^%-%-[a-zA-Z0-9_]+$")
        if key then
          result.opts[key] = true
        end
      end
    else
      -- 必要參數(有區分位子)
      table.insert(result.params, arg)
    end
  end
  return result
end

return M
