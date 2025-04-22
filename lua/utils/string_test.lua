-- lua5.1 string_test.lua
package.path = package.path ..
    ";../?.lua" ..
    ";../testing/?.lua" ..
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua"

local inspect = require("vim.inspect")
local t = require("testing")

local function Example_string_match()
  local str = "ABC_DEF_GHI"
  local ma, mb, mc = string.match(str, "(.*)_(.*)_(.*)")
  print(ma)
  print(mb)
  print(mc)
  local md = string.match(str, "%d")
  print(md)
  local me, mf = string.match(str, "%d") -- 所以如果要確認都匹配到可以用 if me and mf ...
  print(me, mf)
  -- Output:
  -- ABC
  -- DEF
  -- GHI
  -- nil
  -- nil     nil
end

local function Example_string_match_2()
  local str = "ABC_DEF_GHI"
  local matches = { string.match(str, "(.*)_(.*)_(.*)") }
  print("count：" .. #matches)
  print(table.concat(matches, ", "))

  local m = string.match(str, "(.*)_(.*)_(.*)")
  local matches2 = { m } -- 如果是分開來再，就會有辦法解出來完整的內容
  print(inspect(matches2))

  -- Output:
  -- 3
  -- ABC, DEF, GHI
  -- { "ABC" }
  -- ABC DEF GHI
end

local function Example_string_gmatch()
  local tests = {
    { string.gmatch("ABC_DEF", '123(.*)_(.*)'),    {} },
    { string.gmatch("ABC_DE_F", '(.*)_(.*)_(.*)'), { "ABC", "DE", "F" } },
  }
  local is_pass = true
  local errs = { errors = {} }
  for i, item in ipairs(tests) do
    ---@type function
    local matchIter = item[1]
    -- local match1 = matchIter()
    local actual = {}
    for a, b, c in matchIter do -- 這可行，但是要手動因數量而改變
      actual = { a, b, c }
    end
    local expected = item[2]
    if inspect(actual) ~= inspect(expected) then
      table.insert(errs["errors"], string.format('❌ [%d] got: %s want: %s', i, inspect(actual), inspect(expected)))
      is_pass = false
    end
  end

  if is_pass then
    return true
  else
    return errs
  end
end


function Example_string_match_vimgrep()
  local line = "docs/linux.md:13:49:bra xxx ..."
  local path, row, col, desc = string.match(line, "(.-):(%d+):(%d+):(.+)")

  return string.format("%s | %s | %s | %s", path, row, col, desc) ==
      "docs/linux.md | 13 | 49 | bra xxx ..."
end

t.RunTest({
  Example_string_match,
  Example_string_match_2,
  { fn = Example_string_gmatch,        name = "Example_string_gmatch" },
  { fn = Example_string_match_vimgrep, name = "Example_string_match_vimgrep" },
}, arg[1])
