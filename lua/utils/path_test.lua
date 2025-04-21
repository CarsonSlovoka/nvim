package.path  = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local array   = require("utils.array")
local inspect = require("vim.inspect")
local t       = require("testing")

local function Example_extract_path()
  local tests = {
    { "carson:~/.config/nvim$ afddsaf  bbadsf", "~/.config/nvim" },
    { "user123:/usr/local/bin$ test",           "/usr/local/bin" },
    { "alice:~/docs/$",                         "~/docs/" },
    { "no_path:/$ xxx",                         "/" },
    { "invalid",                                "Pattern not found" },
    { "foo:/etc$ no_dollar",                    "/etc" },
  }
  local is_pass = true
  local errs = { errors = {} }
  for i, item in ipairs(tests) do
    local path = item[1]
    local expected = item[2]
    local match = string.match(path, '^.-:([~/].-)%$')
    local actual
    if match then
      actual = match
    else
      actual = "Pattern not found"
    end
    if actual ~= expected then
      table.insert(errs["errors"], string.format('❌ [%d] got: %s want: %s', i, actual, expected))
      is_pass = false
    end
  end

  if is_pass then
    return true
  else
    return errs
  end

  -- :r! /usr/bin/lua5.1 path_test.lua Example_extract_path
end

t.RunTest({
  ["Example_extract_path"] = Example_extract_path,
}, arg[1])
