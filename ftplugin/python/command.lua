local utils = require("utils.utils")
local buf = vim.api.nvim_get_current_buf()
-- vim.api.nvim_create_user_command("FmtPython", -- 這樣的指令創建後會一直都在，切換到非python的檔案也是會有此命令
vim.api.nvim_buf_create_user_command(buf, "FmtPython", -- 使用nvim_buf_create_user_command可以讓此cmd只在這個buf生效
  function(args)
    for _, exe_name in ipairs({ "isort", "black" }) do
      -- 確保有這些執行檔，但是有了也不代表沒問題，有可能是其它Python版本裝的，不能相容到非該版本的Python
      -- 💡 pip freeze | grep -E 'isort|black' # 如果此指令抓的到這兩個內容就沒問題
      if vim.fn.executable(exe_name) == 0 then
        vim.notify(string.format("%s not found. `pip install %s`", exe_name, exe_name), vim.log.levels.WARN)
        return
      end
    end

    local para = utils.flag.parse(args.args)
    local reload = para.opts["reload"] or "1"
    -- 使用外部工具來格式化python
    -- python不像go，有提供go fmt: https://go.dev/blog/gofmt
    -- 或者clangd 有--fallback-style的選項: https://manpages.ubuntu.com/manpages/plucky/man1/clangd-18.1.html
    -- pip install isort black
    vim.cmd("w") -- 要先儲檔才讓外部工具格式化
    -- local msg = vim.fn.system() -- 回傳值為字串，如同終端機直接執行指令後得到的字串(不會特別區分err, 都寫一起)
    -- vim.fn.system("isort " .. vim.fn.expand("%")) -- pip install isort -- 優化import的項目
    -- vim.fn.system("black " .. vim.fn.expand("%")) -- pip install black -- 優化一般的代碼

    ---@type vim.SystemCompleted
    local r

    for _, exe_name in ipairs({
      "isort", -- 優化import的項目
      "black", -- 優化一般的代碼
    }) do
      r = vim.system({ exe_name, vim.fn.expand("%") }):wait()
      if r.code ~= 0 then
        vim.notify(string.format(
            "❌ [%s] err code: %d err msg: %s" ..
            "try `pip install %s` to fix",
            exe_name, r.code, r.stderr,
            exe_name),
          vim.log.levels.WARN)
        return
      end
    end
    if reload == "1" then -- 如果是在 BufWritePre 事件不能再用e
      vim.cmd("e")        -- reload
    end
    -- yapf 這個也是不錯的工具，如果真得想要自定義就可以用這個工具，不然用black, isort足矣
    -- https://github.com/google/yapf
  end,
  {
    nargs = "?",
    complete = function(arg_lead)
      return utils.cmd.get_complete_list(arg_lead, {
        reload = { "1", "0" },
      })
    end,
    desc = "format python"
  }
)
