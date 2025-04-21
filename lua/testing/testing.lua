local M = {}

--- @param allTestFunc table
--- @param inputFuncName string
--- @example RunTest({ func1, func2 }, nil)
--- @example RunTest({ func1, { fn = Example_xx, name="xx" }, { fn = Example_oo, name="oo" } }, "xx") -- test xx function
function M.RunTest(allTestFunc, inputFuncName)
  local foundFunc = false
  for i, item in ipairs(allTestFunc) do
    local curFunc
    local funcName = nil
    if type(item) == "function" then
      curFunc = item
    elseif item["fn"] then
      curFunc = item["fn"]
      funcName = item["name"]
    end


    if inputFuncName == nil or
        inputFuncName == funcName or
        i == tonumber(inputFuncName) then
      funcName = string.format("%s [%d of %d]", funcName or "", i, #allTestFunc)
      foundFunc = true

      --- @type boolean|table
      local result = curFunc()
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
      elseif t == "table" and result["errors"] then
        print(string.format("❌ FAIL: %s", funcName))
        for _, err_msg in ipairs(result["errors"]) do
          print("    " .. err_msg)
        end
      end
    end
  end

  if not foundFunc then
    print("Error: No such function '" .. (inputFuncName or "") .. "'")
  end
end

return M
