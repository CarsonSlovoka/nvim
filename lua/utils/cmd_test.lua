local utils = {}
utils.cmd   = require("utils.cmd")
local t     = require("testing.testing")

local function Test_get_cmp_config()
  local fargs = { "arg1", "arg2", "msg=hello", "key=543" }
  local opt = utils.cmd.get_cmp_config(fargs)
  if opt.key ~= "543" or opt.msg ~= "hello" then
    print(vim.inspect(opt))
    return false
  end

  if #fargs ~= 4 then
    return { errors = { "fargs應當不變，固總數需相同" } }
  end

  opt = utils.cmd.get_cmp_config(fargs, true)
  if opt.key ~= "543" or opt.msg ~= "hello" then
    return false
  end

  if #fargs ~= 2 then
    return { errors = { "fargs應當被改變" } }
  end

  if fargs[1] ~= "arg1" or fargs[2] ~= "arg2" then
    print(vim.inspect(fargs))
    return false
  end

  return true
end

local function Test_get_cmp_config__attachment()
  local fargs = { "arg1", "id=abc", "file=/path/file1", "file=/path/file2", "file=file3" }
  local opt = utils.cmd.get_cmp_config(fargs)
  -- print(vim.inspect(opt))
  return opt["id"] == "abc" and
      #opt["file"] == 3 and
      opt["file"][3] == "/path/file1" and opt["file"][2] == "/path/file2" and opt["file"][1] == "file3" -- 順序可能會不同
end

t.RunTest({
  { fn = Test_get_cmp_config,             name = "Test_get_cmp_config" },
  { fn = Test_get_cmp_config__attachment, name = "Test_get_cmp_config__attachment" },
}, arg[1])
