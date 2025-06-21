--- @desciption 請餵入filefox匯出的輸籤路徑
--- @usage require("firefox").setup({ bookmark_path = "~/firefox_bookmark.json" })

local utils = require("utils.utils")

local M = {}

--- @param obj table 為firefox導出的書籤(json格式)
--- @param out table
local function parse_bookmark(obj, out)
  if obj == nil then
    return
  end

  if obj.title and obj.uri then
    table.insert(out,
      {
        title = obj.title,
        uri = obj.uri,
      }
    )
  end

  if obj.children == nil then
    return
  end

  for _, children in ipairs(obj.children) do -- ⚠️ 如果children是nil的時候，這樣做會影響後面的執行，會整個都不如預期
    parse_bookmark(children, out)
  end
end

function M.setup(opt)
  local bookmark_list = {}
  if opt.bookmark_path then
    --- @type table
    local bookmark_json = utils.encoding.json.load(vim.fn.expand(opt.bookmark_path))
    parse_bookmark(bookmark_json, bookmark_list)
  end

  vim.api.nvim_create_user_command("FirefoxOpen",
    function(args)
      if args.fargs[1] == "" then
        vim.notify("missing uri", vim.log.levels.ERROR)
        return
      end
      -- if utils.os.IsWindows then
      --   os.execute(string.format("firefox %s > nul 2>&1", args.fargs[1]))
      -- else
      --   os.execute(string.format("firefox %s > /dev/null 2>&1", args.fargs[1]))
      -- end
      -- vim.fn.system("firefox " .. args.fargs[1]) -- 用這個比較好，不會有多餘的輸出干擾 -- 不過會鎖住，要等待網頁關閉

      vim.loop.spawn("firefox", { args = { args.fargs[1] } })
    end,
    {
      desc = "打開firefox指定的書籤頁",
      nargs = 1,
      complete = function(arg_lead)
        if #bookmark_list == 0 then
          return {
            "https://www.mozilla.org/"
          }
        end

        local comps = {}
        for _, item in ipairs(bookmark_list) do
          -- if item.title:match() -- match預設是用正則式
          if string.find(item.title, arg_lead, 1, true) or
              string.find(item.uri:lower(), arg_lead:lower(), 1, true) -- 1 開始索引, plain不使用正則式
          then
            table.insert(comps, item.uri)
          end
        end
        return comps
      end
    }
  )
end

return M
