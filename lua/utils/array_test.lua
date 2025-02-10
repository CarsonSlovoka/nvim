-- /usr/bin/lua5.1 array_test.lua

package.path  = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local array   = require("utils.array")
local inspect = require("vim.inspect")
local t       = require("testing")

local function Example_Merge()
  local a1 = { 1, 2 }
  local a2 = { "a", "b" }
  print(inspect(array.Merge(a1, a2, { 3, 4 })))
  -- :r! /usr/bin/lua5.1 array_test.lua Example_Merge
  -- Output:
  -- { 1, 2, "a", "b", 3, 4 }
end

t.RunTest({
  ["Example_Merge"] = Example_Merge,
}, arg[1])
