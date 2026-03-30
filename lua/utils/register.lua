local M = {}

--- 取得所有可能的 register 名稱
function M.get_registers()
  local regs = {}
  -- 常用 registers: a-z, A-Z, 0-9, ", -, _, *, +, /, :, ., %, #
  for i = string.byte('a'), string.byte('z') do
    table.insert(regs, string.char(i))
  end
  for i = string.byte('A'), string.byte('Z') do
    table.insert(regs, string.char(i))
  end
  for i = 0, 9 do
    table.insert(regs, tostring(i))
  end
  local special = { '"', '-', '_', '*', '+', '/', ':', '.', '%', '#' }
  for _, r in ipairs(special) do
    table.insert(regs, r)
  end
  return regs
end

return M
