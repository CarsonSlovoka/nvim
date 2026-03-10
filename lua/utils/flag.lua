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

---@param arg_lead string
---@param options table   { short_name, long_name, complete... }
---@return table?
function M.get_complete(arg_lead, options)
  if arg_lead:sub(1, 1) ~= "-" then
    return nil
  end
  local matches = {}
  local lead = vim.split(arg_lead, "=") -- 為了讓--filetype=ma 時按下tab還可以有補全
  local lead_key = lead[1]
  local lead_val = lead[2]
  for _, opt in ipairs(options) do
    local short_name = opt[1]
    local long_name = opt[2]
    local vals = opt[3]
    if short_name:sub(1, #lead_key) == lead_key or
        long_name:sub(1, #lead_key) == lead_key then
      local key = long_name:sub(1, #lead_key) == lead_key and long_name or short_name

      if vals then
        for j in ipairs(vals) do
          if lead_val then
            if vals[j]:sub(1, #lead_val) == lead_val then
              -- 只推入val與當前的lead_val相符的項目就好
              table.insert(matches, key .. "=" .. vals[j])
            end
          else
            table.insert(matches, key .. "=" .. vals[j])
          end
          if lead_key == "-" or lead_key == "--" then
            -- 每一個項目只出現一次，只用第一筆來代表
            break
          end
        end
      else
        table.insert(matches, key)
      end
    end
  end
  return matches
end

return M
