local utils = require("utils.utils")

vim.api.nvim_buf_create_user_command(vim.api.nvim_get_current_buf(), "Mv", -- 重新命名圖片
  function(args)
    -- 解析 Markdown 圖片語法 ![alt](path/to/old.png), 並重新命名
    -- ![alt](path/to/old.png) => ![new](newPath/xxx/new.png)

    local text = utils.range.get_selected_text()[1]

    -- ![]()
    local alt, old_path = text:match("!%[(.-)%]%((.-)%)")
    if not old_path then
      vim.notify("No valid picture grammar found", vim.log.levels.ERROR)
      return
    end
    local new_path = args.fargs[1]

    -- 獲取新的檔名 (basename) 做為新的 alt text (選擇性)
    local new_basename = new_path:match("^.+/(.+)$") or new_path
    local new_alt = vim.fn.fnamemodify(new_basename, ':t:r') -- t: tail; r: remove last extension

    -- 執行檔案重新命名 (mv)
    local success, err = os.rename(old_path, new_path)
    if success then
      local new_text = string.format("![%s](%s)", new_alt, new_path)
      -- 可行，但是往上貼有不是取代原本的內容
      -- local after = false     -- 'P'
      -- vim.api.nvim_put({ new_text }, "l", after, true)

      -- Tip: 保存在剪貼簿，手動貼上, 再用normal的方式去置換
      vim.fn.setreg('"', new_text)
      vim.cmd("normal! viWP")
    else
      vim.notify("Failed to change the name: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    end
  end,
  {
    desc = "rename image: ![alt](path/to/old.png) => ![new](newPath/xxx/new.png)",
    range = true,
    nargs = 1,
    complete = function()
      local text = utils.range.get_selected_text()[1]
      local _, old_path = text:match("!%[(.-)%]%((.-)%)")
      if old_path then
        return { old_path }
      end
    end

  }
)
