--- cmd_center.lua 讓輸入的cmd可以正畫面的中間

--- TODO 指令補全也可以補全其參數
--- TODO 按 ↑ 可以代出上一個指令

local M = {}

local buf = vim.api.nvim_create_buf(false, true)    -- 創建不可列出, 也不可編輯的buf
vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
vim.api.nvim_buf_set_name(buf, 'plugin:cmd-center') -- 命名緩衝區

-- local win = vim.api.nvim_open_win(buf, true, win_config)
-- win_config["win"] = win

vim.fn.prompt_setprompt(buf, ':') -- 這如果都是固定的可以只設定一次，之後每次都會是如此
vim.fn.prompt_setcallback(buf,
  function(input)
    if M.range == 2 then
      input = "'<,'>" .. input
    end
    -- vim.cmd(input) -- 這個得不到輸出的結果
    vim.api.nvim_set_current_win(M.parent_win) -- 在進入的該視窗執行指令，不然像 :pu=xx 它輸出的地方會不如預期
    local result = vim.api.nvim_exec2(input, { output = true })
    print(result.output)
    -- vim.cmd("mes")
    vim.api.nvim_win_close(M.win, true)
    -- vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- 如果是手動q掉視窗, 是不會觸發到 prompt_setcallback 所以最好是用autocmd來確保
  end
)

-- vim.api.nvim_win_hide(win)
-- vim.api.nvim_buf_delete(buf, { force = true })

local ns_id_hl = vim.api.nvim_create_namespace('cmd-center_highlight') -- Creates a new namespace or gets an existing one.
vim.api.nvim_set_hl(ns_id_hl, "FloatBorder", { fg = "#ff00ff" })       -- :help FloatBorder

vim.keymap.set({ "n", "v" }, "<leader>:",
  function()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" then
      M.range = 2
      vim.fn.prompt_setprompt(buf, "'<,'>")
    else
      M.range = 0
      vim.fn.prompt_setprompt(buf, "'<,'>")
      vim.fn.prompt_setprompt(buf, ':')
    end
    local height = vim.api.nvim_win_get_height(0)
    local width = vim.api.nvim_win_get_width(0)
    local win_config = { -- 是可以寫在外層，但是希望是抓當前的視窗大小來決定
      relative = 'win',
      width = math.floor(width / 2),
      -- height = math.floor(height / 2),
      height = 5,
      row = math.floor(height / 4),
      col = math.floor(width / 4),
      border = "rounded",
      -- border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
      -- border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
      -- border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
      title = "Command", -- 僅在有border時才會出來
      title_pos = "center",
    }
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf }) -- prompt最後一列輸入後會觸發prompt_setcallback
    M.parent_win = vim.api.nvim_get_current_win()
    M.win = vim.api.nvim_open_win(buf, true, win_config)              -- 如果執行nvim_open_win時已經vim.api.nvim_win_hide(win)，那麼會被報錯
    vim.api.nvim_win_set_hl_ns(M.win, ns_id_hl)
    vim.cmd("startinsert")
  end,
  {
    desc = "cmd的輸入可以顯示在畫面中間",
    noremap = true,
  }
)

local group = vim.api.nvim_create_augroup("cmd-center", {})
-- vim.api.nvim_create_autocmd("InsertLeave", 用WinLeave比InsertLeave好，不然如果想要往上用visual複製之前的訊息，此時的buftype如果被改成nofile, 就失去prompt的作用了
vim.api.nvim_create_autocmd("WinLeave",
  {
    desc = "set buftype = nofile",
    group = group,
    buffer = buf,
    callback = function()
      vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- 如果不改成nofile, 當buffer有修改時會出現: no write since last change
    end,
  }
)

-- 設置命令補全
vim.api.nvim_set_option_value("omnifunc", "v:lua._cmd_center_complete", { buf = buf })     -- <C-X><C-O>
vim.api.nvim_set_option_value("completefunc", "v:lua._cmd_center_complete", { buf = buf }) -- <C-X><C-U>
_G._cmd_center_complete = function(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local start = col
    while start > 0 and string.sub(line, start, start) ~= ":" do
      start = start - 1
    end
    return start
  else
    local commands = vim.api.nvim_get_commands({})
    local matches = {}
    for cmd, _ in pairs(commands) do
      if vim.startswith(cmd, base) then
        table.insert(matches, cmd)
      end
    end
    return matches
  end
end
-- 設置按鍵映射
-- vim.api.nvim_buf_set_keymap(buf, "i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<C-x>\<C-o>"]], 👈 無效
vim.api.nvim_buf_set_keymap(buf, "i", "<Tab>", [[<C-x><C-o>]],
  { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(buf, "i", "<S-Tab>", [[<C-x><C-o>]],
  { noremap = true, silent = true })
