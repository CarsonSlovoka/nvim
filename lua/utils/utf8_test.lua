package.path = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local utf8   = require("utils.utf8")                        -- NOTE: 不能用/usr/bin/lua5.1來執行, 因為你面有 require("bit") 是屬於luajit的東西
local t      = require("testing.testing")
local vim    = {}
-- vim.fn      = require("vimfn") -- /usr/share/nvim/runtime/lua/vim/_meta/vimfn.lua # package.path可了也還是不行
vim.inspect  = require("vim.inspect")


local function Example_utf8codes()
  local s      = "你好a字"
  local result = {}
  for unicode in utf8.codes(s) do
    -- vim.fn.nr2char(unicode)
    table.insert(result, string.format("%d (0x%X)", unicode, unicode))
  end
  -- :lua print(vim.fn.nr2char(20320)) -- 你
  -- =nr2char(20320) -- (同上)
  return vim.inspect(result) == [[{ "20320 (0x4F60)", "22909 (0x597D)", "97 (0x61)", "23383 (0x5B57)" }]]
end

t.RunTest({
  { fn = Example_utf8codes, name = "Ex_utf8codes" }, -- /usr/bin/luajit utf8_test.lua Ex_utf8codes
}, arg[1])
