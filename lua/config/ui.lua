-- :help ui2

local GROUP_AUTO_CMD_PAGER = vim.api.nvim_create_augroup('AutoCommandPager', { clear = true })

local M = {
  pending = false,
  commands = {
    marks = true,
    changes = true,

    -- 此三者相同
    ls = true,
    buffers = true,
    files = true,

    -- ju, jumps 同
    ju = true,
    jumps = true,

    -- registers, di, dis, display 皆相同
    registers = true,
    di = true,
    dis = true,
    display = true,
    ['!'] = true,
  }
}


local function init_ui2()
  require('vim._core.ui2').enable({
    enable = true,
    msg = {
      -- targets
      -- - cmd 是預設, 如果是cmd要自己再用 g< 去打開輸出, 太麻煩
      -- - msg 類似一個會彈出的窗口
      -- targets = 'pager' 設定成 pager, 除了:marks會連print, vim.notify這些也都會連動. 不然這種是還不錯，而且都是接著寫，之前的不會清除
      -- :help ui-messages  -- 它有提到可以設定成table, 就可以針對個別的項目
      targets = {
        -- ❗ 目前這樣的設定沒有用, 就算用了targets去各別設定，還是需要用 g< 去開輸出
        -- Note: pager 它是一個buffer, 可以用 <C-w>T 分到新的頁籤. 接著輸出會同步
        [""] = "msg",
        empty = "cmd",
        bufwrite = "msg",
        confirm = "cmd",
        emsg = "pager",
        echo = "msg",
        echomsg = "msg",
        echoerr = "pager",
        completion = "cmd",
        list_cmd = "pager", -- :ls, :set, ...
        lua_error = "pager",
        lua_print = "msg",
        progress = "pager",
        rpc_error = "pager",
        quickfix = "msg",
        search_cmd = "cmd",
        search_count = "cmd",
        shell_cmd = "pager",
        shell_err = "pager",
        shell_out = "pager",
        shell_ret = "msg",
        undo = "msg",
        verbose = "pager",
        wildlist = "cmd",
        wmsg = "msg",
        typed_cmd = "cmd",
      },
      cmd = {
        height = 0.5,
      },
      dialog = {
        height = 0.5,
      },
      msg = {
        height = 0.3,
        timeout = 5000,
      },
      pager = {
        height = 0.5,
      },
    }
  })
end

function M:setup()
  init_ui2()

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = GROUP_AUTO_CMD_PAGER,
    pattern = ':',
    callback = function()
      self.pending = false
      if vim.v.event.abort then
        return
      end
      -- 當離開command時，去讀取command-line的輸入
      local ok, cmd = pcall(
        vim.api.nvim_parse_cmd,
        vim.fn.getcmdline(),
        {}
      )

      -- 當輸入符合commands的內容時，就on起pending
      if ok and self.commands[cmd.cmd] then
        self.pending = cmd.nextcmd == ''
            and not cmd.mods.silent
            and #(cmd.range or {}) == 0
      end
    end,
  })

  vim.api.nvim_create_autocmd('SafeState', { -- SafeState 可以在閒置時, 達到等待動作
    group = GROUP_AUTO_CMD_PAGER,
    callback = function()
      -- 在pending時，使用 g< 去開啟最後的cmd輸出, 如此就不需要再手動用g<開啟
      if not self.pending or vim.api.nvim_get_mode().mode ~= 'n' then
        return
      end

      self.pending = false
      vim.cmd('normal! g<')
    end,
  })
end

return M
