local M = {}

local bit = require("bit") -- 屬於luajit的東西

--- 遍歷字串(UTF-8 碼點), 取得到unicode的碼點(rune)
---
--- NOTE:(如果是在lua5.3會有utf8.codes可用，但是LuaJIT要自己實現)
---
--- @param s string
--- @return function
function M.codes(s)
  local i = 1
  local len = #s
  return function()
    if i > len then return nil end
    local c = string.byte(s, i)

    local code
    if c < 0x80 then
      code = c
      i = i + 1
    elseif c < 0xE0 then
      code = bit.bor(
        bit.lshift(bit.band(c, 0x1F), 6),
        bit.band(string.byte(s, i + 1), 0x3F)
      )
      i = i + 2
    elseif c < 0xF0 then
      code = bit.bor(
        bit.lshift(bit.band(c, 0x0F), 12),
        bit.lshift(bit.band(string.byte(s, i + 1), 0x3F), 6),
        bit.band(string.byte(s, i + 2), 0x3F)
      )
      i = i + 3
    else
      code = bit.bor(
        bit.lshift(bit.band(c, 0x07), 18),
        bit.lshift(bit.band(string.byte(s, i + 1), 0x3F), 12),
        bit.lshift(bit.band(string.byte(s, i + 2), 0x3F), 6),
        bit.band(string.byte(s, i + 3), 0x3F)
      )
      i = i + 4
    end

    return code
  end
end

return M
