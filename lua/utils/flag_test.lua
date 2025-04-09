-- /usr/bin/lua5.1 flag_test.lua Test_flag_parse

package.path = package.path ..
    ";../?.lua" ..                                          -- utils.xxx
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local flag   = require("utils.flag")
local t      = require("testing")

local function Test_flag_parse()
  -- 綜合測試
  local para = flag.parse("para1 para2 --opt=value1 --opt2=value2")
  print(para.params[1])
  print(para.opts["opt2"])

  -- 測試僅有opt
  local para2 = flag.parse("--opt=value1 --opt2=value2")
  print(#para2.params)
  print(para2.opts["opt"])

  -- 測試僅有param
  local para3 = flag.parse("require1 require2")
  print(para3.params[2])
  print(#para2.opts)

  -- Output:
  -- para1
  -- value2
  -- 0
  -- value1
  -- require2
  -- 0
end

t.RunTest({
  ["Test_flag_parse"] = Test_flag_parse,
}, arg[1])
