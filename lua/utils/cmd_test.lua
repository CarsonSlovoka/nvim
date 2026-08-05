-- `nvim -u NORC -l cmd_test.lua`

local utils   = {}
utils.cmd     = require("utils.cmd")
-- local t       = require("testing.testing")
local testing = require("testing") -- https://github.com/CarsonSlovoka/testing.nvim
local t       = testing.new()

t:test("test: utils.cmd.get_cmp_config", function()
  local fargs = { "arg1", "arg2", "msg=hello", "key=543" }
  local opt = utils.cmd.get_cmp_config(fargs)
  t:eq(
    opt,
    -- { key = 543, msg = "hello" }, -- 注意，得到的543是字串
    { key = "543", msg = "hello" },
    "opt " .. vim.inspect(opt)
  )
  t:truthy(#fargs == 4, "fargs應當不變，固總數需相同")

  opt = utils.cmd.get_cmp_config(fargs, true)
  t:truthy(#fargs == 2, "fargs應當被改變")
  t:truthy(fargs[1] == "arg1")
  t:truthy(fargs[2] == "arg2")
end)

t:test("test: utils.cmd.get_cmp_config (attachment)", function()
  local fargs = { "arg1", "id=abc", "file=/path/file1", "file=/path/file2", "file=file3" }
  local opt = utils.cmd.get_cmp_config(fargs)
  t:eq(
    opt,
    {
      id = "abc",
      file = {
        -- 順序是反過來的！
        "file3",
        "/path/file2",
        "/path/file1",
      }

    },
    "opt " .. vim.inspect(opt)
  )
end)

local success = t:finish()
if not success then
  vim.cmd.cquit(1)
end
