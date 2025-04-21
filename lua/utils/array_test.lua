-- /usr/bin/lua5.1 array_test.lua

package.path  = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local array   = require("utils.array")
local inspect = require("vim.inspect")
local t       = require("testing")

local function Example_inspect()
  local pass = true
  local errs = { errors = {} }
  for i, item in ipairs({
    { inspect(1),        "1" },
    { inspect("Hello"),  '"Hello"' },
    { inspect({ 1, 2 }), "{ 1, 2 }" },
    { inspect({ a = 1, b = 2 }),
      [[{
  a = 1,
  b = 2
}]]
    },
    { inspect({ 1, 2, a = 1, b = 2 }),
      [[{ 1, 2,
  a = 1,
  b = 2
}]] },
    { inspect({ a = { b = 2 } }),
      [[{
  a = {
    b = 2
  }
}]]
    },
    {
      inspect({ f = print }),
      [[{
  f = <function 1>
}]]
    },
    {
      inspect(setmetatable({ a = 1 }, { b = 2 })),
      [[{
  a = 1,
  <metatable> = {
    b = 2
  }
}]]
    },
  }) do
    local actual, expected = item[1], item[2]
    if actual ~= expected then
      pass = false
      table.insert(errs["errors"], string.format('❌ [%d] got: %s want: %s', i, actual, expected))
    end
  end
  return pass or errs
end

local function Example_Merge()
  local a1 = { 1, 2 }
  local a2 = { "a", "b" }
  return inspect(array.Merge(a1, a2, { 3, 4 })) == inspect({ 1, 2, "a", "b", 3, 4 })
end

t.RunTest({
  Example_inspect,                           -- /usr/bin/lua5.1 array_test.lua 1
  { fn = Example_Merge, name = "Ex_merge" }, -- /usr/bin/lua5.1 array_test.lua Ex_merge -- /usr/bin/lua5.1 array_test.lua 2
}, arg[1])
