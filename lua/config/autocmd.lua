local utils = require("utils.utils")

local M = {
  autoSave = true,
  autoReformat = true,
  autoMarkRange = true,
  callback = function(module) end
}
local create_autocmd = vim.api.nvim_create_autocmd

--- FzfLua autocmds 配合fuzzy search很容易找到自動命令來自何處
local groupName = {
  autoSave = "carson.autoSave",
  editorconfig = "carson.editorconfig",
  highlightHexColor = "carson.highlightHexColor",
  highlightSpecial = "highlightSpecial",
  highlight = "carson.highlight",
  filetype = "filetype",
  binaryViwer = "binaryViwer",
  conceal = "carson.conceal",
  largeFile = "carson.largeFile",
}
for key, name in pairs(groupName) do
  if name == groupName.editorconfig then
    vim.api.nvim_create_augroup(name, { clear = true })
  else
    vim.api.nvim_create_augroup(name, {})
  end
end


function M.setup(opts)
  for k, v in pairs(opts) do
    if M[k] ~= nil then
      M[k] = v
    end
  end

  -- print(vim.inspect(M))

  vim.keymap.set("i", "<C-O>", function()
      if not M.autoSave then
        return "<C-O>"
      end
      -- local orgSetting = M.autoSave
      M.autoSave = false -- 因為<C-O>會暫時離開Insert模式，就會導致觸發了InsertLeave的事件，這不是我們所期望的，因此就先關閉
      -- print("🧊", M.autoSave)
      vim.defer_fn(function()
        -- M.autoSave = orgSetting -- 可行，但是多此一舉
        M.autoSave = true
        -- print("🔥", M.autoSave)
      end, 50)
      return "<C-O>"
    end,
    {
      desc = "若AutoSave開啟，則暫時關閉後再開啟. 並執行預設行為: execute one command, return to Insert mode",
      noremap = false, -- 允許遞歸映射以執行原始 <C-O> 行為
      expr = true,
    }
  )

  local last_insert_time = 0 -- 用於延遲存檔用, 如果中途有在編輯就不會存檔
  vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
      last_insert_time = vim.fn.reltimefloat(vim.fn.reltime())
      -- print("last_insert_time 已更新: ", last_insert_time)
    end,
  })

  -- 設定 autocmd，當離開 buffer 時自動存檔
  vim.api.nvim_create_autocmd('BufLeave', {
    group = groupName.autoSave,
    pattern = '*',
    callback = function()
      -- 檢查 buffer 是否已修改且可寫
      if vim.bo.modified and vim.bo.modifiable and vim.bo.buftype == '' then
        vim.cmd('write')
        vim.notify(
          string.format("%s Buffer %q saved before leaving.", os.date("%Y-%m-%d %H:%M:%S"), vim.fn.bufname()),
          vim.log.levels.INFO
        )
      end
    end,
  })

  create_autocmd(
    {
      -- "TextChanged", -- 如果用x, ce, undo, redo...也會觸發 -- 不要新增，否則redo會因為儲檔後無法復原
      "InsertLeave",
    },
    {
      pattern = "*",
      -- command="silent write"
      group = groupName.autoSave,
      callback = function()
        if not M.autoSave then
          return
        end

        local buf = vim.api.nvim_get_current_buf() -- 避免中途會切換到其它的檔案, 記錄Leave時的buf
        local filename = vim.fn.expand("%:t")
        local cur_file_path = vim.fn.expand("%")   -- 當前文件路徑

        -- 使用 vim.defer_fn 延遲 2.5 秒執行
        vim.defer_fn(function()
          local cur_time = vim.fn.reltimefloat(vim.fn.reltime())
          if cur_time - last_insert_time >= 2.5 then -- 如果這2.5秒內又進入編輯，就不會觸發保存，如此就可以避免立即儲檔的不便
            -- print(cur_time, last_insert_time)

            if filename == "" then
              -- 表示當前的檔案可能是No Name，也就是臨時建出來尚未決定名稱的檔案
              return
            end

            if not vim.api.nvim_get_option_value("modifiable", { buf = buf }) then -- 這是能不能編輯，至於是不是readonly不能用這個判斷，有可能是可以編輯，但是為readonly(不能儲)
              -- 不可編輯 (但是否唯讀然未知)
              return
            end

            -- :lua print(vim.bo[vim.api.nvim_get_current_buf()].readonly)
            -- local bufnr = vim.api.nvim_get_current_buf()
            -- if vim.bo[bufnr].readonly then -- vim.bo.readonly 如果只需要判斷當前的buf，則如此即可
            if vim.bo.readonly then
              -- 唯讀檔也不動作
              return
            end

            -- 獲取當前緩衝區的 buftype
            -- 因為只有 `buftype` 為空的緩衝區才可以執行 `:write` 命令。如果 `buftype` 為其它值（如 `nofile`、`help`、`prompt` 等），應該跳過保存操作
            -- local buftype = vim.api.nvim_buf_get_option(0, "buftype"  )
            local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })

            -- 當 buftype 為空時才執行保存: 你可以嘗試用telescope的輸入視窗用insert，此時的buftype是prompt就不是空的
            if buftype == "" and
                vim.bo.modified -- 可以曉得是否真的有異動
            then
              -- ~~-- 理論上換到其它地方還是可以保存，但目前先用提醒的方式就好(反正如果最後沒有保存nvim還是會要求要動作)~~ 目前已經新增BufLeave, 因此不需要此判斷了
              -- if cur_file_path ~= vim.fn.expand("%") then
              --   vim.api.nvim_echo({
              --     { "⚠️ 檔案尚未保存: ", "Normal" },
              --     { cur_file_path, "@label" },
              --   }, true, {})
              --   return
              -- end

              if M.autoReformat then
                if vim.bo.filetype == "python" then
                  vim.cmd("FmtPython --reload=0")
                  vim.defer_fn(function()
                    vim.cmd("silent e")
                  end, 50) -- 要等到InsertLeave才能重載，不然會有錯
                  return   -- 它是透過外部工具來格式化，會有reload，沒辦法保存tag，所以不需要後續動作
                elseif vim.bo.filetype == 'javascript' then
                  if vim.fn.executable("prettier") == 0 then
                    vim.notify("Unable to format xml, missing formatting tool: `prettier`", vim.log.levels.WARN)
                  else
                    -- Tip: 對於附檔名不是js的檔案，可以用--parser來告知: `prettier -w my.jxa --parser babel` 也可以寫在 prettierrc 用 overrides 的方式
                    -- ❌ ~~prettier -w my.jxa --parser javascript~~ 新的版本, 用的是babel
                    local cmd = string.format("!prettier -w %s --parser babel", cur_file_path)
                    vim.cmd(cmd)
                    vim.cmd("e!")
                    vim.api.nvim_echo({
                      { os.date("%Y-%m-%d %H:%M:%S") .. " do format with command: ", "Normal" },
                      { cmd,                                                         "@label" },
                    }, false, {})
                  end
                  return
                elseif vim.bo.filetype == 'xml' then
                  if vim.fn.executable("xmlstarlet") == 0 then
                    vim.notify("Unable to format xml, missing formatting tool: `xmlstarlet`", vim.log.levels.WARN)
                  else
                    vim.cmd("%!xmlstarlet fo")
                    vim.cmd("silent w")
                    vim.api.nvim_echo({
                      { os.date("%Y-%m-%d %H:%M:%S") .. " do format with command: ", "Normal" },
                      { '%!xmlstarlet fo',                                           "@label" },
                    }, false, {})
                  end
                  return
                end
              end

              -- 先手動觸發 BufWritePre 自動命令 (去除多餘的空白、格式化、保存tag等等)
              vim.api.nvim_exec_autocmds("BufWritePre", {
                pattern = cur_file_path
              })

              vim.cmd("silent write") -- 如果文件是被外部工具改變這時候用write就會被尋問是否要載入
              vim.notify(
                string.format("%s %s saved.", os.date("%Y-%m-%d %H:%M:%S"), cur_file_path),
                vim.log.levels.INFO
              )
              -- vim.api.nvim_input("i<ESC>") -- 手動觸發再離開，為了讓`^標籤可以不被lsp格式化影響
              vim.api.nvim_input("i<ESC>m^") -- 直接再執行m^來加入最後使用i的位置 -- ⚠️ 其它的command如果跑出來i可能是此導致

              -- elseif not vim.bo.modified then
              --  vim.notify("未檢測到變更，跳過保存", vim.log.levels.DEBUG)
              -- else
              --  vim.notify(string.format("跳過保存，因為 buftype 為 '%s'", buftype), vim.log.levels.WARN)
            end
          end
        end, 2500)
      end,
    }
  )

  -- vim.keymap.set({ "v", "x" } -- x包含v, V. 但沒有Ctrl-V 而v會包含，並且包含所有x涵蓋的項目
  -- local enable_mark_range = true
  -- for _, key in ipairs({ "c", ":",
  --   "/",
  --   "C", -- ["x]C Delete from the cursor position to the end of the line
  --   "I", -- 區塊選取時會用到
  --   "A", -- 區塊選取時會用到
  --   "R", -- 取代時會用到，例如: 3Rf0 https://vi.stackexchange.com/a/25129/31859
  -- }) do
  --   vim.keymap.set("v", key, function()
  --       enable_mark_range = false
  --       vim.defer_fn(function()
  --         enable_mark_range = true
  --       end, 50)
  --       return key
  --     end,
  --     {
  --       desc = "暫時停止sign m<, m>的行為，避免c的時候被多打上m<, m>",
  --       noremap = false,
  --       expr = true,
  --     }
  --   )
  -- end

  -- https://vi.stackexchange.com/a/44191/31859
  local begin_visual_position
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = { "*:[vV\x16]*" },
    callback = function()
      -- if not enable_mark_range then
      --   return
      -- end
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
      if buftype ~= "" then
        return
      end

      if M.autoMarkRange then
        -- vim.api.nvim_input("m<") -- 這樣沒用，因為還是在visual的情況，只能等到結束在設定
        begin_visual_position = vim.api.nvim_win_get_cursor(0) -- [row, col]
        -- print("Enter", vim.v.event.old_mode, vim.v.event.new_mode) -- :h ModeChanged -- n, v -- n, V 抓不到c
        -- print("Enter", vim.api.nvim_get_mode().mode) -- 這也抓不到c
      end
    end,
    desc = "VisualEnter 標記開始選取的位置"
  })
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = { "[vV\x16]*:*" },
    callback = function()
      -- if not enable_mark_range then
      --   return
      -- end
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
      if buftype ~= "" then
        return
      end
      if M.autoMarkRange and begin_visual_position then
        local cur_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_win_set_cursor(0, begin_visual_position)
        -- TODO 以下全部都失敗
        -- vim.api.nvim_input("m<") -- < 不行但是>可以
        -- vim.api.nvim_input("m<lt>")
        -- vim.api.nvim_feedkeys("m<", "n", false)
        -- vim.api.nvim_feedkeys("m<lt>", "n", false)
        vim.api.nvim_win_set_cursor(0, cur_pos)
      end
      if M.autoMarkRange then
        -- print("Leave", vim.v.event.old_mode, vim.v.event.new_mode) -- v, n -- V, n
        -- vim.cmd("normal! m>") -- 用這個變成不會觸發到自定義的keymap
        -- vim.api.nvim_input("m>") -- 這可能會照成誤輸入到m>的情況發生，要額外去寫這些判斷很麻煩

        -- 已知bug, 如果是下反白到上時的位置是顛倒的

        -- https://github.com/CarsonSlovoka/nvim/blob/ea6d7d9c684410ec75ec594de874491e46f26796/lua/config/sign_define.lua#L36-L45
        local sd = require("config.sign_define")
        local sign_id = vim.api.nvim_create_namespace(sd.group .. "_>")
        local line = vim.api.nvim_win_get_cursor(0)[1]
        vim.fn.sign_unplace(sd.group, { buffer = vim.fn.bufnr(), id = sign_id })
        vim.fn.sign_place(sign_id, sd.group, "MarkPin>", vim.fn.bufnr(), { lnum = line })
      end
    end,
    desc = "VisualLeave 標記結束選取的位置"
  })

  create_autocmd(
    { "BufRead", "BufNewFile" },
    {
      -- group = vim.api.nvim_create_augroup("highlightSpecial", {}),
      group = groupName.highlightSpecial,
      pattern = "*",
      callback = function()
        local groupCJKWhiteSpace = "CJKFullWidthSpace"
        vim.fn.matchadd(groupCJKWhiteSpace, '　') -- 創建群組(群組名稱如果不存在似乎會自己建立)對應關係: 匹配U+3000
        -- vim.fn.matchadd(groupCJKWhiteSpace, 'A') -- 可以這樣添加其他要內容

        -- 設定此群組的高亮
        vim.api.nvim_set_hl(0, groupCJKWhiteSpace, {
          -- bg = 'red',   -- 背景色
          -- fg = 'white', -- 前景色
          bg = "#a6a6a6",
          fg = '#00ffff',
          -- 你也可以添加其他屬性，例如：
          -- bold = true,
          -- italic = true,
          -- underline = true
        })

        -- local groupTODO = "TODO"
        -- -- vim.fn.matchadd(groupTODO, 'TODO:? .*') -- 無效
        -- vim.fn.matchadd(groupTODO, 'TODO .*')
        -- vim.api.nvim_set_hl(0, groupTODO, { fg = "#8bb33d", italic = true })

        -- https://github.com/orgs/community/discussions/16925
        local highlights = {
          -- 用 <> 包起來可以確定不是是其它的字，例如: MyNote, NoteXxx 都不會中
          -- ` \\?` 前面允許有空白
          -- 首字母要求大寫
          -- `:\\? \\?` 最後面可以有`: `或是僅有`:`都行
          { name = "NOTE",       fg = "#FFFFFF", bg = "#0000FF", pattern = " \\?\\<N[Oo][Tt][Ee]\\>:\\? \\?" },
          { name = "USAGE",      fg = "#FFFFFF", bg = "#179797", pattern = " \\?\\<U[Ss][Aa][Gg][Ee]\\>:\\? \\?" },
          -- { name = "USAGE",      fg = "#060402", bg = "#24EBEB", pattern = " \\?\\<U[Ss][Aa][Gg][Ee]\\>:\\? \\?" },
          { name = "TODO",       fg = "#000000", bg = "#8bb33d", pattern = " \\?\\<T[Oo][Dd][Oo]\\>:\\? \\?" },
          { name = "WARNING",    fg = "#020505", bg = "#FFA500", pattern = " \\?\\<W[Aa][Rr][Nn]\\([Ii][Nn][Gg]\\)\\?\\>:\\? \\?" }, -- ing可以不一定要有
          { name = "FIXME",      fg = "#F8F6F4", bg = "#EA6890", pattern = " \\?\\<F[Ii][Xx][Mm][Ee]\\>:\\? \\?" },
          { name = "TIP",        fg = "#323225", bg = "#99CC00", pattern = " \\?\\<T[Ii][Pp][Ss]\\?\\>:\\? \\?" },
          { name = "IMPORTANT",  fg = "#F1F2E6", bg = "#FF00FF", pattern = " \\?\\<I[Mm][Pp][Oo][Rr][Tt][Aa][Nn][Tt]\\>:\\? \\?" },
          { name = "ERROR",      fg = "#F1F2E6", bg = "#FF0000", pattern = " \\?\\<E[Rr][Rr]\\([Oo][Rr]\\)\\?\\>:\\? \\?" },
          { name = "CAUTION",    fg = "#F1F2E6", bg = "#FF0000", pattern = " \\?\\<C[Aa][Uu][Tt][Ii][Oo][Nn]\\>:\\? \\?" },
          { name = "DEPRECATED", fg = "#FFFFFF", bg = "#696969", pattern = "\\<D[Ee][Pp][Rr][Ee][Cc][Aa][Tt][Ee][Dd]\\>" },
          {
            name = "STRIKETHROUGH",
            fg = "#8b949e",
            pattern = "\\~\\~.*\\~\\~",
            bold = false,
            strikethrough = true,
          },
          {
            name = "HYPERLINK",
            fg = "#00c6ff", -- #00a6ff #00d3f5
            -- fg = "#ffffff", bg = "#0167CC",
            underline = true,
            -- [[ \zshttps\?:\/\/\S*]]
            -- pattern = [[ \zshttps\?:\/\/[a-zA-Z0-9#?./=_%-]*]], -- 一開始沒空白也會失敗
            pattern = [[\<https\?:\/\/[a-zA-Z0-9#?./=_%-:]*\>]],
          },
        }
        for _, hl in ipairs(highlights) do
          local hl_name = "@" .. hl.name
          vim.api.nvim_set_hl(0, hl_name,
            {
              -- TIP: 屬性如果是 nil 會用預設值
              fg = hl.fg,
              bg = hl.bg,
              bold = hl.bold,
              strikethrough = hl.strikethrough,
              underline = hl.underline,
            }
          )
          -- vim.fn.matchadd(hl_name, "\\c \\?\\<" .. hl.name .. "\\> \\?") -- 前後如果有空白也會一併加上背景色(這樣比較明顯)
          vim.fn.matchadd(hl_name, hl.pattern)
        end
      end
    }
  )

  -- 以下的autocmd可以用: vim.filetype.add({ extension = { gs = "javascript", } }) 就可行了
  -- create_autocmd(
  --   { "BufRead", "BufNewFile" },
  --   {
  --     desc = ":set filetype=javascript",
  --     group = groupName.filetype,
  --     pattern = "*.gs",
  --     callback = function()
  --       vim.bo.filetype = "javascript"
  --     end
  --   }
  -- )

  -- vim.api.nvim_clear_autocmds({ pattern = "*.otf" }) -- 這也阻止不了，要從vim.g.zipPlugin_ext直接改 -- otf也包含在內 https://github.com/neovim/neovim/blob/90b682891dd554f06805b9536ad7228b0319f23b/runtime/plugin/zipPlugin.vim#L33-L52
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" },
    {
      group = groupName.binaryViwer,
      desc = "opentype file viwer",
      pattern = {
        -- 當pattern都無法觸發，可以先用 :Telescope autocommands 觀察受何者影響
        "*.ttf",
        "*.otf", -- 🧙 如果其它的autocmd有用到，要清除它，不然會被影響無法觸發
      },
      callback = function()
        vim.bo.filetype = "opentype" -- 也將原本的ttf, otf的filetype做更改
      end
    }
  )

  vim.api.nvim_create_autocmd({ "BufRead" },
    {
      group = groupName.binaryViwer,
      desc = "show file info",
      pattern = {
        "*.png", "*.bmp", "*.ico",
        "*.webp", "*.webm",
        "*.jpeg", "*.jpg",
        "*.mp4", "*.mp3",
      },
      callback = function(e)
        if vim.fn.executable("file") == 0 or vim.fn.executable("ls") == 0 then
          return
        end

        local abspath = vim.fn.expand("%:p")

        if vim.env.KITTY_WINDOW_ID ~= nil then
          local ext = string.lower(vim.fn.fnamemodify(e.file, ":e")) -- png
          local hijack_file_patterns = {
            png = true,
            jpg = true,
            jpeg = true,
            gif = true,
            webp = true,
            avif = true,
            ico = true,
          }
          if hijack_file_patterns[ext] then
            -- 直接用image.nvim來顯示就好, 不過還是再開一個視窗寫入基本訊息
            -- WARN: 必須再開一個視窗因為image.nvim的會先執行，該buf寫不進去(可以可以先改成可寫再變唯讀？沒試過)
            vim.cmd("vert botright split | enew | setlocal buftype=nofile noswapfile")
            utils.buf.set_lines(vim.api.nvim_get_current_buf(), 0, {
              {
                { "filepath: ", "" },
                { abspath,      "@label" },
              },
              {},
              {
                { vim.fn.system([[ls -lh ]] .. abspath):gsub('\n', ''), "" },
              },
              {
                { vim.fn.system(string.format([[file %s ]], abspath)):gsub('\n', ''), "" },
              },
            })
            return
          end
        end

        local filename = "♻️" .. vim.fn.expand("%:t") -- 為了盡量避免與當前的buf同名，前面加上♻️

        -- 🟧 建一個buf
        local org_bug_id = vim.api.nvim_get_current_buf()
        vim.cmd("enew")              -- 開一個新的buffer
        -- vim.cmd("bw " .. org_bug_id) -- 不要當前的這一個檔案, w 會連<C-O>, <C-I>都沒辦法再跳轉過來 (就其實可以討論，但目前先不要留它)
        vim.cmd("bd " .. org_bug_id) -- bw確定會讓一些檔案沒辦法正常顯示，例如比較大一點的ico, 用bd可行

        vim.api.nvim_set_option_value("buftype", "nofile", { buf = 0 })
        vim.api.nvim_buf_set_name(0, filename)

        -- 🟧 一開始放上一些自定義的內容
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
          "filepath: " .. abspath,
          "",
        })

        local ns_id = vim.api.nvim_create_namespace("hightlight_comment")
        vim.cmd("normal! G") -- 移到底部，讓 nvim_win_get_cursor 的位置是所想要的

        -- 🟧 接著放上一些提示可以使用的指令 並且用 Comment來突顯
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local helps = {
          -- 注意xxd 的option要放在前面，而且-c與-C是不同的
          string.format(":r! xxd -c 16 %s", abspath), -- 如果要看二進位的資料，提示使用者可以用xxd來查看
          string.format("gimp %s", abspath),
          string.format("foot yazi %s", abspath),     -- <leader><F5>
          string.format("kitty +kitten icat %s", abspath),
          "",
        }
        -- vim.api.nvim_buf_set_lines(0, row, -1, false, helps) -- 由於最後故意給了一個""當成空行，不想要這個空行也變成Comment
        vim.api.nvim_buf_set_lines(0, row, row + #helps - 1, false, helps) -- 經確的算出Comment的位子
        vim.hl.range(0, ns_id, "Comment", { row, 0 }, { #helps, -1 })


        vim.cmd("normal! G")
        row = vim.api.nvim_win_get_cursor(0)[1]

        -- 🟧 最後放上執行檔輸出的結果
        -- local r = vim.system({ "file", abspath }):wait() -- 可行，但是沒有辦法用pipe line, 所以要透過sh -c來
        local r = vim.system({ "sh", "-c",
          -- 先 ls -lh 再用echo ''讓其輸出多一列空行, 最後執行file
          string.format("ls -lh %s && echo '' && file %s | tr ',' '\n'", abspath, abspath),
        }):wait()
        if r.code ~= 0 then
          vim.notify(string.format("❌ run `file` error. err code: %d %s", r.code, r.stderr), vim.log.levels.WARN)
          return
        end
        vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(r.stdout, "\n"))


        vim.cmd([[
          " 開頭是 xxx:
          syntax match @label /^\w*:/

          " 2710x1234
          syntax match @type /\d\+x\d\+/
        ]])

        if vim.env.KITTY_WINDOW_ID == nil then
          vim.cmd("Chafa " .. abspath)
        end
      end
    }
  )

  if not pcall(require, "ccc") then
    -- ccc 插件已經有類似的功能就不再重覆 (而且它連前景色也會考慮，也就是會自動搭配合適的前景色)

    -- 如果想要前景，背景搭配一起看可以考慮使用以下方法
    -- :lua vim.api.nvim_set_hl(0, "@Qoo123", { fg = "#ff00ff", bg = "#00ff00" })
    -- :call matchadd('@Qoo123', 'TEST_COLOR')
    -- 也可以用 :'<,'>Highlight #ff00ff_#00ff00

    -- 自定義命名空間（用於高亮
    vim.g.highlight_spy = "bg" -- fg, all, #00ff00
    local ns_highlight_hex_or_rgb = vim.api.nvim_create_namespace('carson_color_highlights')
    create_autocmd({
      "BufEnter", "TextChanged", "TextChangedI",
      -- "InsertLeave",
    }, {
      desc = '將文字 #RRGGBB 給予顏色. 例如: #ff0000  #00ff00 #0000ff. :let g:highlight_spy="" :e', -- 當調整完後可以用:e來刷新
      pattern = "*",
      group = groupName.highlightHexColor,
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        -- 清空之前的高亮（避免重複）
        -- vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1) -- 這會清除所有，可能會勿清
        vim.api.nvim_buf_clear_namespace(buf, ns_highlight_hex_or_rgb, 0, -1) -- 清理還是需要的，不然刪除後再打上其它內容還是會有突顯

        -- 遍歷每一行
        for lnum, line in ipairs(lines) do
          -- 匹配 #RRGGBB
          for color in line:gmatch('#%x%x%x%x%x%x') do
            -- 找到顏色代碼的起始和結束位置
            local start_col = line:find(color, 1, true) - 1
            local end_col = start_col + #color

            -- 動態創建高亮組，背景色設為該顏色
            local hl_group = 'Color_' .. color:sub(2) -- 去掉 # 作為高亮組名
            if vim.g.highlight_spy == "bg" then
              vim.api.nvim_set_hl(0, hl_group, { bg = color })
            elseif vim.g.highlight_spy == "fg" then
              vim.api.nvim_set_hl(0, hl_group, { fg = color })
            elseif vim.g.highlight_spy == "all" then
              vim.api.nvim_set_hl(0, hl_group, { bg = color, fg = color })
            elseif vim.g.highlight_spy:match("#%x%x%x%x%x%x") then -- 將其視為fg的顏色
              vim.api.nvim_set_hl(0, hl_group, { bg = color, fg = vim.g.highlight_spy })
            end


            -- 應用高亮到緩衝區
            -- vim.api.nvim_buf_add_highlight(buf, ns_highlight_hex_or_rgb, hl_group, lnum - 1, start_col, end_col) -- DEPRECATED IN 0.11 https://neovim.io/doc/user/deprecated.html
            vim.api.nvim_buf_set_extmark(buf, ns_highlight_hex_or_rgb, lnum - 1, start_col,
              {
                end_col = end_col,
                hl_group = hl_group,
              }
            )
          end
        end
      end,
    })

    --[[ 我是覺得不必要清除，就算在insert下顯示也不是什麼壞事
    -- 進入插入模式時只清除 color_highlights 命名空間的高亮
      vim.api.nvim_create_autocmd("InsertEnter", {
        desc = '插入模式下取消hex的顏色突顯',
        pattern = "*",
        group = groupName.highlightHexColor,
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_clear_namespace(buf, ns_highlight_hex_or_rgb, 0, -1)
        end,
      })
    --]]
  end



  -- trim_trailing_whitespace
  create_autocmd(
    "BufWritePre", -- 在寫入前執行的動作
    {
      desc = "格式化和去除結尾多餘的space, tab",
      pattern = "*",
      callback = function()
        -- 對於不可修改的檔案，就不做操作，不然嘗試修改會被報錯, 例如: :copen 中想用:w 寫到其它地方就會有問題
        if not vim.bo.modifiable then
          return
        end

        local auto_fmt = M.autoReformat
            and not (
              vim.bo.filetype == "python" -- 如果是python用外部工具來格式化
              or vim.bo.filetype == "sql" -- sql 如果用它的lsp 會遇到錯誤: SQLComplete:The dbext plugin must be loaded for dynamic SQL completion 因此就不使用
              or vim.bo.filetype == "xml"
            )

        local support_lsp = false
        if auto_fmt then
          -- 檢查是否有LSP客戶端附加到當前的緩衝區
          local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
          for _, client in ipairs(clients) do
            -- 也就檢查是否有支持格式化的功能
            if client:supports_method("textDocument/formatting") then
              support_lsp = true
              break
            end
          end

          -- lsp格式化 和 保存標籤
          if support_lsp then                                                           -- 這部份是保存標籤，而由於python是用外部工具來格式化，保存標籤的這段不適用它
            -- 保存當前所有用戶定義的標記 (a-z, A-Z)
            local marks = vim.fn.getmarklist('%')                                       -- 獲取當前緩衝區的標籤 -- 這個只會保存小寫的內容a-Z
            for char in string.gmatch("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^.", ".") do -- 大寫的用這樣來取得
              -- for char in string.gmatch("[0-9A-Z]", ".") do -- ❌ 這是錯的，這也只會得到: [, 0, 9, A, -, Z, ]
              -- print(char)
              local mark = "'" .. char
              local pos = vim.fn.getpos(mark)
              -- lua print(vim.inspect(vim.fn.getpos("'^")))
              -- 如果標籤有效（pos[2] 是行號，pos[3] 是列號）
              if pos[2] ~= 0 or pos[3] ~= 0 then
                -- marks[mark] = pos
                table.insert(marks, {
                  mark = mark,
                  pos = pos,
                })
              end
            end
            --[[ 顯式處理特殊標籤 '^ 和 '. 似乎沒有效，改用vim.api.nvim_input("i<ESC>")的方式來觸發`^
            for _, mark in ipairs({ "'^", "'." }) do
              local pos = vim.fn.getpos(mark)
              if pos[2] ~= 0 or pos[3] ~= 0 then
                marks[mark] = pos
              end
            end
            --]]
            -- print(vim.inspect(marks))

            -- vim.cmd("FmtPython") -- 不能再這邊格式化，因為裡面也會save, 這樣會導致一直有BufWritePre

            vim.lsp.buf.format({
              async = false,
              timeout_ms = 3000,
            })
            local fmt_msg = string.format("%s lsp.buf.format done", os.date("%Y-%m-%d %H:%M:%S"))
            vim.notify(fmt_msg, vim.log.levels.INFO)

            -- 恢復標籤
            for _, mark in ipairs(marks) do
              -- if mark.mark:match("^'[0-9a-zA-Z^.]") then
              --   vim.fn.setpos(mark.mark, mark.pos)
              -- end
              vim.fn.setpos(mark.mark, mark.pos)
            end
          else
            vim.notify("No LSP formatter available for current file, skipping format. Turn off msg `:SetAutFmt 0`",
              vim.log.levels.WARN)
          end
        end

        if not auto_fmt or not support_lsp or vim.bo.filetype == "sh" then
          -- 如果有格式化，多餘的空白，應該都會被除掉，所以這個動作只需要在沒有格式化的文件使用即可
          -- 其實就是使用vim的取代%s/.../...
          -- \s\+  \s+ 任意空白字符(空格, 制表符等)一個或多個
          -- 取代為空白
          -- e flags, 如果發生錯誤的時候不報錯
          vim.cmd([[%s/\s\+$//e]])
        end
      end
    }
  )

  local predefined_extensions = {
    -- 以下內容定義在vim.filetype.add({...})之中
    birdfont = true
  }

  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      pattern = "*", -- :set ft?

      callback = function(e)
        if not vim.bo.readonly and vim.o.fileformat ~= "unix" then
          print(string.format("set fileformat from `%s` to `unix`", vim.o.fileformat)) -- 提示使用者有被自動轉換，使其如果不滿意還可以自己再轉回去
          vim.o.fileformat = "unix"
        end
        local ext = string.lower(vim.fn.fnamemodify(e.file, ":e"))
        if predefined_extensions[ext] then
          return
        end
        vim.opt_local.expandtab = true -- 使用空白代替Tab :set et?  -- :set expandtab -- :set et
        vim.opt_local.tabstop = 4      -- Tab鍵等於4個空白
        vim.opt_local.softtabstop = 4  -- 在插入模式下，Tab鍵也等於4空白
        vim.opt_local.shiftwidth = 4   -- 自動縮進時使用 4 個空白
      end,
      desc = "indent_style=Space, indent_size=4"
    }
  )
  create_autocmd(
    "FileType", -- 不是檔案的附檔名，要用 :set filetype 查看才是準的
    {
      group = groupName.editorconfig,
      pattern = {
        "md",
        "yml", "yaml",
        "json", "json5", "jsonc",
        "toml",
        "xml", "svg", "ttx",
        "gs",
        "gohtml", "gotmpl",
        "html",
        "js", "javascript", "mjs", "ts", "mts",
        "css", "scss", "sass",
        "lua",
        "vue",
        "sh", "zsh",
        "dart",
      },
      callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
      end,
      desc = "indent_style=Space, indent_size=2"
    }
  )
  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      -- pattern = "go",
      pattern = { "go", "puml", "nsi", "nsh", "Makefile", "mk" },
      callback = function()
        vim.opt_local.expandtab = false -- :set noexpandtab -- :set noet
        -- 以下還是可以設定，如果你想要讓tab看起來隔比較密(緊)可以考慮以下
        -- vim.opt_local.tabstop = 2
        -- vim.opt_local.softtabstop = 2
        -- vim.opt_local.shiftwidth = 2
      end,
      desc = "indent_style=tab"
    }
  )
  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      pattern = {
        "dosbatch" -- bat
      },
      callback = function()
        vim.o.fileformat = "dos"
      end,
      desc = "fileformat=dos crlf"
    }
  )

  create_autocmd(
    {
      -- 如果不曉得是哪一個可以先用 "BufRead", "BufNewFile" 來觀察
      -- BufReadPost   -- 讀完了, 用這個也不對
      "Syntax"
    },
    {
      group = groupName.conceal,
      pattern = { -- 用在FileType事件有用，其它的用e去篩選 -- Note: 如果是Syntax事件，pattern也會有用, 但必須定義group才可以！
        "json", "jsonc"
      },
      callback = function(e)
        -- print(vim.inspect(e))

        -- local ext = string.lower(vim.fn.fnamemodify(e.file, ":e"))
        -- if ext ~= "json" and ext ~= "jsonc" then
        --   return
        -- end

        -- 👇 以下無效了，可能被ensure_installed的項目影響到了
        -- vim.cmd("silent! syntax clear jsonEndCommon") -- 如果怕有重覆可以清除, 但不是無法使用的問題所在
        -- vim.cmd([[syntax match jsonEndCommon /,$/ conceal]])

        -- vim.cmd在autocommand回呼執行時，還沒到buffer就緒的階段
        -- 因此使用schedule讓它安排到下一個event-loop, 如此Syntax可以確定已經載入完畢，再次執行就可以成功了
        vim.schedule(function()
          vim.cmd([[syntax match jsonEndCommon /,$/ conceal]]) -- 將結尾的,隱藏
        end)
      end,
      desc = "conceal ,$ for filetype={json, jsonc}"
    }
  )

  create_autocmd({ 'Syntax' }, {
    group = groupName.conceal,
    pattern = { 'xml' },
    callback = function()
      vim.wo.conceallevel = 2
      vim.schedule(function()
        -- vim.cmd([[syntax match XmlQuote /="\zs[^"]*\ze"/ conceal]]) -- 隱藏屬性值
        -- vim.cmd([[syntax match XmlQuoteStart /=\zs"\ze/ conceal ]])
        -- vim.cmd([[syntax match XmlQuoteEnd /="[^"]*\zs"\ze/ conceal ]])
        -- vim.cmd([[syntax match XmlQuoteEnd /[^"]*\zs"\ze/ conceal ]])
        -- vim.cmd([[syntax match XmlQuoteStart /="/ conceal cchar=✅ ]])
        -- vim.cmd([[syntax match XmlQuoteEnd /=\zs"\ze[^"]*\zs"\ze/ conceal ]]) -- 只會有最後一個zs ze的效果
        -- vim.cmd([[syntax match XmlQuoteStart /[a-zA-Z]*=\zs"\ze[^"]*"/ conceal ]])
        -- vim.cmd([[syntax match XmlQuoteEnd /="[^"]*\zs"\ze/ conceal]])
        -- 當 XmlQuoteStart, XmlQuoteEnd 都有時，只會 XmlQuotesStart有用

        vim.cmd([[syntax match XmlQuote /"/ conceal ]]) -- 直接隱藏所有的分號，缺點是註解的內容也會被影響
        vim.api.nvim_echo({
          { "❗ \n", "Normal" },
          { "\"", "@label" },
          { " 已經被自動隱藏\n", "Normal" },
          { "使用: \n", "Normal" },
          { ":syntax clear", "@label" },
          { "可以取消", "Normal" },
        }, false, {})
      end)
    end,
  })

  create_autocmd("TermOpen",
    {
      callback = function()
        -- https://neovim.io/doc/user/terminal.html#terminal-config
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
      end,
      desc = "set number, set relaivenumber"
    }
  )

  vim.g.lspcmp = 1
  ---@type table
  local default_trigger_charact_map = {} -- 記錄每一個檔案的預設 triggerCharacters
  create_autocmd('LspAttach', {
    -- https://neovim.io/doc/user/lsp.html
    desc = "auto-completion. 在`.`的時候會自動觸發補全 Note: Use CTRL-Y to select an item.",
    group = vim.api.nvim_create_augroup('my.lsp', {}),
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      -- if client:supports_method('textDocument/implementation') then
      --   -- Create a keymap for vim.lsp.buf.implementation ...
      -- end
      -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
      if client:supports_method('textDocument/completion') then
        -- 每一個文件載入的時候，都會觸發一次，如果這個文件已經觸發了將不會再觸發，不過可以使用 :e 來重載
        -- Optional: trigger autocompletion on EVERY keypress. May be slow!
        -- print("before " .. vim.inspect(client.server_capabilities.completionProvider.triggerCharacters)) -- go的預設是.  lua的預設是\t, \n, . ,... 會比較多
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        if default_trigger_charact_map[filetype] == nil then
          default_trigger_charact_map[filetype] = client.server_capabilities.completionProvider.triggerCharacters
        end
        if vim.g.lspcmp == 1 then
          local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
          client.server_capabilities.completionProvider.triggerCharacters = chars
          -- print("after " .. vim.inspect(client.server_capabilities.completionProvider.triggerCharacters))
        else
          client.server_capabilities.completionProvider.triggerCharacters = default_trigger_charact_map[filetype]
          -- print("default " .. vim.inspect(client.server_capabilities.completionProvider.triggerCharacters))
        end
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
      end
      -- -- Auto-format ("lint") on save.
      -- -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
      -- if not client:supports_method('textDocument/willSaveWaitUntil')
      --     and client:supports_method('textDocument/formatting') then
      --   vim.api.nvim_create_autocmd('BufWritePre', {
      --     group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
      --     buffer = args.buf,
      --     callback = function()
      --       vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
      --     end,
      --   })
      -- end
    end,
  })

  vim.g.cmplistauto = 0 -- :help completefunc
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function()
      if vim.g.cmplistauto == 1 then -- ⚠️ 啟用會受到triggerCharacters影響，所以可以先設定為 vim.g.lspcmp = 0
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local prev_char = col > 1 and line:sub(col - 1, col - 1) or ''
        if prev_char:match('[0-9a-zA-Z]') then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-x><C-u>', true, false, true), 'n', true)
        end
      end
    end,
  })

  -- vim.api.nvim_create_autocmd({ "BufEnter" }, {
  --   group = groupName.conceal,
  --   callback = function()
  --     -- vim.cmd([[ syntax match MyGroup "\~/" conceal cchar=🏠 containedin=ALL]])
  --     -- vim.cmd([[ syntax match MyGroup "ok" conceal cchar=🆗 containedin=ALL]])
  --     -- vim.cmd([[ syntax match MyGroup "\[x\]" conceal cchar=✅ containedin=ALL]])
  --     -- vim.cmd([[ syntax match MyGroup "\cTODO" conceal cchar=📝 containedin=ALL]]) -- \c無效，只有大小有匹配
  --     vim.cmd([[ syntax match MyGroup /\cTODO/ conceal cchar=📝 containedin=ALL]])
  --   end,
  -- })


  -- :h compl-autocomplete

  --[[ 以下是vs2010的mfc專案可能會有這樣的需求，你可以把這段放到 my-customize.lua 自己添加
  (因為不曉得是不是所有rc, rc2都是如此，為了避免有爭議，讓使用者自己在 my-customize.lua 中新增 )
  vim.api.nvim_create_autocmd(
    "FileType",
    {
      -- group = groupName.editorconfig,
      pattern = {
        "rc",
        -- "conf" -- "rc2" -- .ignore的檔案也是conf -- 因此不建議調整，通常這種檔案都會有bom，所以fileencoding如果有ucs-bom是可以直接識別，而不需要特別告知
      },
      callback = function()
        vim.o.fileencoding = "utf-16le"
        vim.o.fileformat = "dos"
      end,
      desc = "crlf, utf-16le"
    }
  )

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = { "resource.h" },
    callback = function()
      vim.o.fileencoding = "utf-16le"
      vim.o.fileformat = "dos"
    end,
    desc = "crlf, utf-16le"
  })
  --]]

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    desc = "set filetype=jsonc",
    group = groupName.filetype,
    pattern = "manifest.json",
    callback = function()
      -- vim.bo.filetype = "json5"
      vim.bo.filetype = "jsonc"
    end,
  })

  -- vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  --   desc = "set filetype=requirements",
  --   group = groupName.filetype,
  --   pattern = "requirements.txt", -- 預設就會有。如果沒有，可能是檔名沒有匹配(少了s之類的)
  --   callback = function()
  --     -- https://github.com/neovim/neovim/blob/4f3aa7bafb75b/runtime/syntax/requirements.vim#L1-L67
  --     vim.bo.filetype = "requirements"
  --   end,
  -- })
  --

  vim.api.nvim_create_autocmd("BufReadPre", {
    desc = "set foldmethod=manual 讀取大檔案不卡頓",
    group = groupName.largeFile,
    pattern = "*",
    callback = function(args)
      local file = args.file
      local stat = vim.uv.fs_stat(file)
      local max_filesize = 3 * 1024 * 1024 -- 3MB

      -- TODO: 已知問題，會遇到錯誤: E201: *ReadPre autocommands must not change current buffer 不過似乎不會有其它不良的影響

      if stat and stat.size > max_filesize then
        local exit = false
        vim.ui.select({ "Yes", "No" }, {
            prompt = "Whether you want to open with vi",
          },
          function(choice, idx)
            if idx == nil then
              -- abort
              return
            end

            if string.lower(choice or "no") == "yes" then
              local buf = vim.api.nvim_get_current_buf()

              vim.fn.jobstart("vi -n " .. file, { -- -n no swap
                term = true,
                on_exit = function()
                  vim.api.nvim_buf_delete(buf, { force = true })
                end
              })

              exit = true
            end
          end
        )

        if exit then
          return
        end

        -- ~~vim.cmd("tabnew | setlocal buftype=nofile noswapfile")~~
        vim.opt_local.foldmethod = "manual" -- 這個很關鍵！ 如果一開始是indent等到載入後再改成manual就來不急了，所以要在Read之前就要設定

        -- 剩下的真的有需要可以手動執行
        -- vim.cmd("syntax off")
        -- vim.cmd("filetype off")

        -- vim.opt_local.swapfile = false
        -- vim.opt_local.undofile = false
        -- vim.opt_local.bufhidden = "unload"

        -- if vim.treesitter then
        --   vim.cmd("TSBufDisable highlight")
        -- end

        vim.fn.setloclist(0, {
          { text = ":syntax off" },
          { text = ":set filetype=" },
          { text = ":filetype off" },
          { text = ":filetype plugin off" },
          { text = ":TSBufDisable highlight" },
          { text = ":TSBufEnable highlight" },
          { text = ":autocmd!" }, -- 移除所有自動命令
        }, 'a')

        vim.notify(
          string.format(
            "%0.3f MB > 3MB 已停用部分功能（大檔案模式）see more :lopen",
            stat.size / (1024 * 1024)
          ),
          vim.log.levels.WARN)
      end
    end,
  })

  vim.api.nvim_create_autocmd('TextYankPost', {
    group = groupName.highlight,
    callback = function()
      -- vim.highlight is deprecated. Feature will be removed in Nvim 2.0.0
      -- vim.highlight.on_yank({
      vim.hl.on_yank({
        higroup = 'IncSearch',
        timeout = 700,
      })
    end,
    desc = 'Highlight yanked text',
  })


  -- render-markdown.nvim 在(da6a7b2 2026-01-03)開始，需要自己寫autocmd來觸發才會有效果 https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/da6a7b25471ab23824f3429225973186eb0b62d2/tests/minimal_init.lua#L33-L39
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('Highlighter', {}),
    pattern = 'markdown',
    callback = function(args)
      vim.treesitter.start(args.buf)
    end,
  })

  if opts.callback then
    opts.callback(M)
  end
end

return M
