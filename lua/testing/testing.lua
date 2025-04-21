local M = {}

--- @param allTestFunc table
--- @param funcName string
function M.RunTest(allTestFunc, funcName)
  -- 根據函數名查找並執行對應的函數
  if funcName and allTestFunc[funcName] then
    -- print("Executing function:", func_name)
    --- @type boolean|table
    local result = allTestFunc[funcName]()
    if result == nil then -- 如果沒有回傳值也視為通過
      print(string.format("✅ PASS: %s", funcName))
    end
    local t = type(result)
    if t == "boolean" then
      if result or result == nil then
        print(string.format("✅ PASS: %s", funcName))
      else
        print(string.format("❌ FAIL: %s", funcName))
      end
      return
    end

    if t == "table" and result["errors"] then
      print(string.format("❌ FAIL: %s", funcName))
      for _, err_msg in ipairs(result["errors"]) do
        print("    " .. err_msg)
      end
    end
  else
    print("Error: No such function '" .. (funcName or "") .. "'")
    print("Available functions:")
    for name, _ in pairs(allTestFunc) do
      print("  - " .. name)
    end
  end
end

return M
