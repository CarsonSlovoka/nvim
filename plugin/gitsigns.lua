local plugin = require("gitsigns")
plugin.setup {
  signs = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },
  signs_staged = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
    untracked = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
  numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
  linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
  word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil,  -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },

  on_attach = function(bufnr)
    local function map(mode, l, r, opts)
      -- 簡化設定
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        -- 例如在: gitsigns.diffthis 的視窗開啟時 (<leader>hd)
        vim.cmd.normal({ vim.v.count1 .. ']c', bang = true })
      else
        -- Warn: 用以下方式，有的跳轉是不對的
        -- for _ = 1, vim.v.count1 do
        --   plugin.nav_hunk('next')
        -- end
        plugin.nav_hunk('next', { count = vim.v.count1 })
      end
    end, { desc = '(git)往下找到異動處' })

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ vim.v.count1 .. '[c', bang = true })
      else
        plugin.nav_hunk('prev', { count = vim.v.count1 })
      end
    end, { desc = '(git)往上找到個異動處' })

    -- Actions
    -- map('n', '<leader>hs', plugin.stage_hunk)
    -- map('n', '<leader>hr', plugin.reset_hunk)
    -- map('v', '<leader>hs', function() plugin.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    -- map('v', '<leader>hr', function() plugin.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    -- map('n', '<leader>hS', plugin.stage_buffer)
    -- map('n', '<leader>hu', plugin.undo_stage_hunk)
    -- map('n', '<leader>hR', plugin.reset_buffer)
    -- map('n', '<leader>hn', plugin.next_hunk) -- 同等: plugin.nav_hunk('next')
    map('n', '<leader>hp', plugin.preview_hunk,
      { desc = '(git)Hunk x of x 開啟preview(光標處必需有異動才能開啟), 查看目前光標處的異動, 開啟後常與prev, next使用. 此指令與diffthis很像，但是專注於一列' })

    map('n', '<leader>hb', function()
      plugin.blame_line { full = true }
    end, { desc = '(git)blame 顯示光標處(不限於異動，所有都能)與最新一次commit時的差異' }
    )

    map('v', -- 由於<leader>t對我有用，所以為了避免影響已存在熱鍵的開啟效率，將此toogle設定在view下才可使用
      '<leader>tb', plugin.toggle_current_line_blame,
      { desc = "(git)可以瞭解這一列最後commit的訊息和時間點 ex: You, 6 days, ago - my commit message. 如果不想要浪費效能，建議不用的時候就可以關掉(再下一次指令)" })

    map('n', '<leader>hd', plugin.diffthis,
      { desc = '(git)查看當前文件的所有異動. 如果要看本次所有文件上的異動，可以使用:Telescope git_status' })
    map('n', '<leader>hD', function()
      plugin.diffthis('~')
    end) -- 有包含上一次的提交修改
    -- map('n', '<leader>td', plugin_gitsigns.toggle_deleted)

    -- Text object
    -- map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>') -- 選取而已，作用不大
  end
}
