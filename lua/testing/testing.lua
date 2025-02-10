local M = {}

--- @param allTestFunc table
--- @param funcName string
function M.RunTest(allTestFunc, funcName)
  -- 根據函數名查找並執行對應的函數
  if funcName and allTestFunc[funcName] then
    -- print("Executing function:", func_name)
    allTestFunc[funcName]()
  else
    print("Error: No such function '" .. (funcName or "") .. "'")
    print("Available functions:")
    for name, _ in pairs(allTestFunc) do
      print("  - " .. name)
    end
  end
end

return M
