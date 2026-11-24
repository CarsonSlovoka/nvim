-- 由於keympa.buffer 設定為當前，所以每次buffer有更新都需要重新觸發，不然熱鍵會失效

-- 快捷鍵映射
-- local opts = { buffer = false } -- buffer預設為true，表示對所有項目都能生效

local keymap = require("utils.keymap").keymap
local function map(mode, key, cmd, opts)
  opts = opts or {}
  opts.buffer = true -- 改為ture可以避免當你使用markdown之後用緩衝區開啟其他檔案屬性時也被套用此熱鍵
  keymap(mode, key, cmd, opts)
end
-- local map = function

-- 標題相關
-- map('n', '<Leader>h1', 'i# <ESC>a', opts) -- h按鍵很重要，不要隨便分配，不然用到的時候會有等待時間
-- map('n', '<C-H>1', 'i# <ESC>a') -- ctrl+h不區分大小寫
for i = 1, 6 do
  local hashes = string.rep("#", i)
  map('n',
    '<C-H>' .. i,
    'i' .. hashes .. ' ', -- 最後多補上一個空白
    { desc = "insert <h" .. i .. ">" }
  )
  map('i',
    '<C-H>' .. i,
    hashes .. ' ',
    { desc = "insert <h" .. i .. ">" }
  )
end

-- 格式化文本
map('n', '<leader>b', 'ciw**<C-r>"**<ESC>', { desc = "Bold" }) -- 加粗 -- ciw會剪下一個詞放到暫存器`"` 並進入編輯模式，在編輯模式下<C-r>可以指定要貼上哪一個暫存器的內容
map('n', '<leader>i', 'ciw*<C-r>"*<ESC>', { desc = "Italic" }) -- 斜體
map('v', '<leader>b', 'c**<C-r>"**<ESC>', { desc = "視覺模式下加粗" })
map('v', '<leader>i', 'c*<C-r>"*<ESC>', { desc = "視覺模式下斜體" })
map('v', '<leader>dw', 'c~~<C-r>"~~<ESC>', { desc = "刪除線 strokethrough" })
map('v', '<leader>~', 'c~~<C-r>"~~<ESC>', { desc = "刪除線 strokethrough" })

-- 代碼塊
-- map('n', '<Leader>c', 'I```<ESC>o```<ESC>O', { desc = "插入代碼塊, 可以先打上區塊代碼的名稱" })
-- map('n', '<Leader>c', 'I```<CR>```<C-o>O', { desc = "插入代碼塊, 可以先打上區塊代碼的名稱" })
map('n', '<Leader><leader>`',
  function()
    -- 最麻煩的方式
    -- local autoSaveEnable = require("config.autocmd").autoSave
    -- if autoSaveEnable then -- 這種情況下，它會自動用mi來記錄標籤，所以先暫停不保存標籤
    --   require("config.autocmd").autoSave = false
    -- end
    -- local name = vim.fn.input("codeblock name: ")
    -- if name == "" then
    --   -- 如果用戶未輸入名稱，插入空的代碼塊
    --   name = ""
    -- end
    -- -- 插入代碼塊模板到當前行
    -- local codeblock = {
    --   "```" .. name,
    --   "",
    --   "```"
    -- }
    -- vim.api.nvim_put(codeblock,
    --   "l",  -- (linewise mode) 插入整列(一個新的列)
    --   true, -- 先標之後插入
    --   true  -- follow, true會將光標移動到新插入的最後一列
    -- )
    -- -- 將游標移動到代碼塊的中間，方便用戶輸入代碼
    -- vim.api.nvim_command("normal! kkI")
    -- vim.cmd("startinsert")
    --
    -- if autoSaveEnable then -- 復原
    --   require("config.autocmd").autoSave = true
    -- end

    -- snippet其實也不錯，但沒有什麼必要
    -- vim.snippet.expand("```${1:}\n${2:}\n```")

    return "i```\r```<C-o>k<End>"
  end,
  {
    desc = "insert a code block",
    expr = true
  }
)

-- -- map('v', '<C-L>', "dP", { desc = "Link" })
-- map('v', '<C-L>', function()
--     -- 以下處理有誤，其實不管怎麼樣用的都是P，只是有問題的是 `## AB`這樣的文本，這種選取完AB後用d會需要p，但是根源的做法用成c就可以解決了
--     -- vim.cmd('normal! d')                     -- 會保存在 " -- 此模式無法在expr中使用
--     -- local original_text = vim.fn.getreg('"') -- 使用寄存器獲得選中文本
--     -- local write_mode = ""
--     -- if original_text ~= nil and original_text ~= '' then
--     --   -- local first_char = original_text:sub(1, 1) -- 取得第一個字元
--     --   -- #first_char -- 都是1
--     --   -- local first_byte = string.byte(first_char)
--     --   local first_byte = original_text:byte(1)
--     --   print(first_byte)
--     --
--     --   if first_byte >= 32 and first_byte <= 126 then
--     --     write_mode = "p"
--     --   else
--     --     write_mode = "P"
--     --   end
--     -- else
--     --   vim.notify("Empty content", vim.log.levels.ERROR)
--     --   return
--     -- end
--     --
--     -- -- 用戶輸入的連結
--     -- local link = vim.fn.input("Enter the link: ")
--     -- if link == nil or link == "" then
--     --   vim.notify("No link entered", vim.log.levels.ERROR)
--     --   return
--     -- end
--     --
--     -- -- 格式化為 Markdown 標記
--     -- local markdown_link = string.format("[%s](%s)", original_text, link)
--     -- -- 將格式化後的內容保存在暫存器 "
--     -- vim.fn.setreg('"', markdown_link)
--     --
--     -- -- 替換選中文本
--     -- vim.cmd('normal! ' .. write_mode)
--
--
--     require("config.autocmd").autoMarkRange = false -- 避免觸發mark標記，導致input或多了m>
--     local link = vim.fn.input("Enter the link: ")
--     require("config.autocmd").autoMarkRange = true
--     if link == nil or link == "" then
--       vim.notify("No link entered", vim.log.levels.ERROR)
--       return
--     end
--
--     return string.format("c[<C-R>\"](%s)<Esc>", link)
--   end,
--   {
--     expr = true,
--     desc = "insert Link"
--   }
-- )


local function select_codeblock(inner)
  local api = vim.api
  local ts = vim.treesitter

  -- 確保 Tree-sitter 已經解析目前的 buffer
  ts.get_parser(0, "markdown"):parse()

  -- 取得游標所在的 Markdown node
  local node = ts.get_node({
    ignore_injections = true,
  })

  -- 💡 這個可以查詢type: `:lua print(vim.treesitter.get_node():type())`
  -- 向上尋找 fenced_code_block
  while node and node:type() ~= "fenced_code_block" do
    node = node:parent()
  end

  -- 找不到 code block 時，不進行操作
  if not node then
    return
  end

  -- 如果是 inner，則尋找 code_fence_content
  if inner then
    local content

    for child in node:iter_children() do
      if child:type() == "code_fence_content" then
        content = child
        break
      end
    end

    if not content then
      return
    end

    node = content
  end

  -- 取得 Tree-sitter node 的範圍
  local sr, sc, er, ec = node:range()

  if sr == er and sc == ec then
    return
  end

  -- 轉換成 Neovim 使用的行號
  local first = sr + 1
  local last = ec == 0 and er or er + 1

  if first > last then
    return
  end

  -- 進入 Visual Line mode
  if api.nvim_get_mode().mode ~= "V" then
    vim.cmd("normal! V")
  end

  -- 設定選取範圍的兩端
  api.nvim_win_set_cursor(0, { first, 0 })
  vim.cmd("normal! o")
  api.nvim_win_set_cursor(0, { last, 0 })
end

-- 💡 所謂的omap, 是在y, c, d等等的動作鍵的操作
map({ "x", "o" }, "ic", function()
  select_codeblock(true)
end, {
  buffer = true,
  desc = "Inner code block",
})

map({ "x", "o" }, "ac", function()
  select_codeblock(false)
end, {
  buffer = true,
  desc = "Around code block",
})

-- Function to create markdown link from visual selection
local function create_markdown_link()
  -- Get the visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local line1, col1 = start_pos[2], start_pos[3]
  local line2, col2 = end_pos[2], end_pos[3]
  local bufnr = vim.api.nvim_get_current_buf()

  -- Get the selected text
  local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false) -- 截取每一列的「所有」欄內容. 得到的是一個table，每列佔一個元素
  if #lines == 0 then
    vim.notify("No text selected", vim.log.levels.ERROR)
    return
  end

  -- Handle multi-line selection
  local selected_text = table.concat(lines, '')
  if line1 == line2 then
    -- Single line selection
    selected_text = string.sub(lines[1], col1, col2) -- 取得該列的相關欄範圍
  end

  -- Prompt for the link URL
  local url = vim.fn.input("Enter link URL: ")
  if url == "" then
    vim.notify("Link creation cancelled", vim.log.levels.INFO)
    return
  end

  -- Create the markdown link
  local markdown_link = string.format("[%s](%s)", selected_text, url)

  -- Replace the selected text with the markdown link
  if line1 == line2 then
    -- Single line replacement
    -- 這是重寫整列
    -- local line = lines[1]
    -- local new_line = string.sub(line, 1, col1-1) .. markdown_link .. string.sub(line, col2+1)
    -- vim.api.nvim_buf_set_lines(bufnr, line1-1, line1, false, {new_line})

    -- TODO 要判斷頭和尾是該取多少byte才可以正確的截斷
    vim.api.nvim_buf_set_text(bufnr, line1 - 1, col1 - 1, line2 - 1, col2, { markdown_link })
  else
    -- Multi-line replacement
    vim.api.nvim_buf_set_lines(bufnr, line1 - 1, line2, false, { markdown_link })
  end
end

-- Register the command
vim.api.nvim_buf_create_user_command(0, 'L', function()
  create_markdown_link()
end, {
  desc = "(這個指令會有問題，如果頭或尾的unicode碼點換成utf8超過1byte會有問題) insert link. Usage :'<,'>L",
  range = true
})
