local input = {}

function input.extension()
  local result = vim.fn.input("請輸入附檔名（例如: lua,sh,md):")
  local extensions = {}

  -- 將輸入的附檔名分割成表
  if result and result ~= "" then
    -- 不含,
    for ext in string.gmatch(result, "[^,]+") do
      table.insert(extensions, ext)
    end
  end
  return extensions
end

return input
