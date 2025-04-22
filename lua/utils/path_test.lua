package.path = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local t = require("testing")

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
    -- ^.-: 從字串開頭，匹配到第一個:
    -- [~/] 匹配路徑的開頭，是~或者絕對路徑/, 相對路徑則不需要
    -- .- 非貪婪匹配任意字符，直到下一個模式. 相當於匹配到第一個出現的下一個模式
    -- %$ 其中的%是不要將$視為正則式
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
  { fn = Example_extract_path, name = "Example_extract_path" },
}, arg[1])
