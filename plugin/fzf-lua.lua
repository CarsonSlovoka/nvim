-- https://github.com/ibhagwan/fzf-lua
-- :checkhealth fzf_lua
require("fzf-lua").setup({
  winopts = {
    row = 10,
    col = 0,
    preview = {
      hidden = false, -- 啟動時顯示預覽
    },
    fullscreen = true,
  },
  keymap = {
    builtin = {
      -- ['<C-p>'] = 'preview-up', 👈 預設就是如此
      -- ['<C-n>'] = 'preview-down',
      -- ['<A-h>'] = 'preview-page-left', 沒有這選項
      -- ['<A-l>'] = 'preview-page-right',
      ['<A-p>'] = 'preview-page-up',
      ['<A-n>'] = 'preview-page-down',
      ['<C-t>'] = 'toggle-preview',    -- 用 Ctrl+T 來 toggle 預覽視窗（隱藏/顯示）
      ["<A-f>"] = "toggle-fullscreen", -- 在 `:FzfLua colorschemes`中，方便查看主題顏色
    },
  },
  buffers = {
    actions = {
      -- ["alt-d"] = require("fzf-lua.actions").buf_del, -- 刪除 buffer, 但之後離開視窗了
      ["alt-d"] = function(selected, opts) -- 使其可以像require("telescope.builtin").buffers那樣也可以用alt-d來刪除
        require("fzf-lua.actions").buf_del(selected, opts)

        -- 再重新載入 buffer 清單，保持 fzf 視窗不關閉
        require("fzf-lua").buffers({ fzf_opts = { ["--no-clear"] = "" }, resume = true })
      end
    },
    winopts = {
      preview = {
        vertical = "down:50%", -- preview 顯示在下方，高度 50%（可調整）
        -- border = "rounded",    -- 邊框樣式（可選）
        layout = "vertical",   -- 確保使用垂直佈局 👈 這個才是將preview, 放在下方的關鍵
      },
    },
  }
})

-- require("fzf-lua").register_ui_select()   -- Important: 直接改變預設的動作, 如此才可以做搜尋, 不然預設的select沒有搜尋可以用 -- 相當於 vim.ui.select = xxx 直接更動預設的行為: `cd ~/.local/share/nvim/site/pack/core/opt/fzf-lua/ && git show -p fd244f2a:lua/fzf-lua/providers/ui_select.lua | bat -l lua -P -r 33:47`
-- -- Note: 預設的vim.ui.select很輕量，如果非真得需要篩選，用它還是比較快，所以可以只在有需要用到的地方再加上它就好了
-- require("fzf-lua").deregister_ui_select() -- 可以還原
-- Tip: register_ui_select, deregister_ui_select 皆已經被加入到 :FzfLua 的指令之中了

vim.keymap.set('n', '<leader>st',
  function()
    if vim.bo.filetype == "oil" then
      vim.cmd("cd " .. require("oil").get_current_dir())
    else
      vim.cmd("cd %:p:h")
    end

    -- require("telescope.builtin").git_status()
    require("fzf-lua").git_status({ resume = true })
  end,
  {
    desc = "git status"
  }
)
vim.keymap.set("n", "<leader>fb", function()
    require("fzf-lua").buffers({ resume = true })
    -- vim.api.nvim_input("<F5>") -- ~~toggle-preview-cw buffer的檔案路徑會比較長,所以將preview改到下方~~ 這可行，但是很取巧，直接對buffers.winopts設定是比較好的做法
  end,
  {
    desc = "可以找到最近開啟的buffer. support: Fuzzy Search"
  }
)
