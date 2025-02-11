--- @param mods string
local function getPathExample(mods)
  local myAbsPath = vim.fn.fnamemodify("~/.config/nvim/init.lua", ":p")
  local output = vim.fn.fnamemodify(myAbsPath, ":" .. mods)
  local cmd = string.format('print(vim.fn.fnamemodify("%s", ":%s"))', myAbsPath, mods)
  return string.format([[-- :lua %s
%s
-- Output:
-- %s
]],
    cmd,
    cmd,
    output
  )
end

local M = {
  -- file
  {
    word = "if vim.fn.isdirectory(outputDir) == 0 then end",
    kind = "file",
    info = "0 = not exists",
    abbr = "vim.file.isDirectory"
  },
  {
    word = "if vim.loop.fs_stat(filepath) ~= nil then end",
    kind = "file",
    info = "~= nil = exists",
    abbr = "vim.file.isExists"
  },
  {
    word = 'vim.fn.mkdir(outputDir, "p")',
    kind = "file",
    info = "mkdir",
    abbr = "vim.file.mkdir",
    user_data = {
      example = [[
# 也可以考慮使用系統命令來建立
os.execute('mkdir -p "' .. outputDir .. '"')
]]
    }
  },

  -- path
  {
    word = 'vim.fn.fnamemodify(path, ":p")',
    kind = "path",
    abbr = 'vim.path.getAbsPath',
    info = "abs fullpath",
    user_data = {
      example = getPathExample("p")
    }
  },
  {
    word = 'vim.fn.fnamemodify(path, ":t")',
    kind = "path",
    abbr = 'vim.path.getFilename',
    info = "/home/xxx/temp.sh => temp.sh",
    user_data = {
      example = getPathExample("t")
    }
  },
  {
    word = 'vim.fn.fnamemodify(path, ":h")',
    kind = "path",
    abbr = 'vim.path.getParentDir',
    info = "/home/xxx/temp.sh => /home/xxx",
    user_data = {
      example = getPathExample("h")
    }
  },
  {
    word = 'vim.fn.fnamemodify(path, ":r")',
    kind = "path",
    abbr = 'vim.path.FullButExt',
    info = "路徑無附檔名(設計重新命名可能有用到)",
    user_data = {
      example = getPathExample("r")
    }
  },
  {
    word = 'vim.fn.fnamemodify(path, ":e")',
    kind = "path",
    abbr = 'vim.path.getExt',
    info = "/home/xxx/temp.sh => sh",
    user_data = {
      example = getPathExample("e")
    }
  },
  {
    word = 'vim.fn.fnamemodify(path, ":~")',
    kind = "path",
    abbr = 'vim.path.expand',
    info = [[
/home/user/temp.sh => ~/temp.sh
(要能換掉必須真的有匹配才行)

# 以下例子無法被換掉
/home/NotExists/temp.sh => /home/NotExists/temp.sh
]],

    user_data = {
      example = getPathExample("~")
    }
  },
}

return M
