vim.diagnostic.config({
  virtual_lines = {
    current_line = true
  },
  -- virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "󰋼", -- 💠󰋼 -- 例如: markdown中的連結不存在: Unresolved reference
      [vim.diagnostic.severity.HINT] = "󰌵",
    },
  },
  float = {
    border = "rounded",
    format = function(d) -- 用熱鍵 ]d 會顯示 :h ]d
      return ("%s (%s) [%s]"):format(d.message, d.source, d.code or d.user_data.lsp.code)
    end,
  },
  underline = true,
  jump = {
    float = true,
  },
})

vim.api.nvim_create_user_command(
  "SetDiagnostics",
  function(args)
    if args.fargs[1] == "1" then
      vim.diagnostic.enable()
      vim.notify("diagnostic enable", vim.log.levels.INFO)
    elseif args.fargs[1] == "0" then
      -- vim.diagnostic.disable() -- 已被棄用
      vim.diagnostic.enable(false)
      vim.notify("diagnostic disable", vim.log.levels.INFO)
    end
  end,
  {
    nargs = 1,
    complete = function()
      return { "1", "0" }
    end,
    desc = "set diagnostic"
  }
)

vim.keymap.set("n", "gbh", function()
    vim.lsp.buf.hover()
  end,
  {
    desc = "💪 vim.lsp.buf.hover() 查看定義與使用方法 (可用<C-W><C-W>跳到出來的窗口)"
  }
)

vim.api.nvim_create_user_command(
  "LspBufDocSymbol",
  function(args)
    -- :lua vim.lsp.buf.document_symbol() -- 👈 可以如此，預設會直接寫到location list去
    vim.lsp.buf.document_symbol({
      on_list = function(result)
        local target_kind = args.fargs[1] or "Function"
        -- print(vim.inspect(result))
        local symbols = result.items or {}
        local list = {}

        local cur_line = vim.fn.line(".")
        local select_idx = 0
        for i, symbol in ipairs(symbols) do -- i從1開始
          if symbol.kind == target_kind then
            if symbol.lnum <= cur_line then
              select_idx = i
            end
            table.insert(list, {
              filename = vim.api.nvim_buf_get_name(0),
              lnum = symbol.lnum,
              col = symbol.col,
              text = symbol.text,
            })
          end
        end

        -- vim.fn.setqflist(list, 'r')
        vim.fn.setloclist(0, list, 'r')
        vim.cmd('lopen')
        if select_idx > 0 then         -- 不能是 :cc 0 只能是正整數
          -- vim.cmd('cc ' .. select_idx) -- 可以不用copen也來cc
          vim.cmd('ll ' .. select_idx) -- location list用ll qflist用cc
        end
      end
    })
  end,
  {
    desc = 'for item in vim.lsp.buf.document_symbol.items if item.kind == "Function"',
    nargs = "?",
    complete = function()
      -- local kind_table = {}
      vim.lsp.buf.document_symbol({
        on_list = function(result) -- 這個不會傳到外層，獨立的一個session，變數不共用
          local kind_table = {}
          for _, symbol in ipairs(result.items) do
            if kind_table[symbol.kind] == nil then
              kind_table[symbol.kind] = true
            end
          end
          local kinds = {}
          for kind, _ in pairs(kind_table) do
            table.insert(kinds, kind)
          end

          vim.w.cur_lsp_buf_document_symbol = table.concat(kinds, ",") -- 會有延遲到補全，但總比都沒有好
        end
      })
      local cmp = {}

      if vim.w.cur_lsp_buf_document_symbol then
        cmp = vim.split(vim.w.cur_lsp_buf_document_symbol, ",")
      end
      return cmp
    end
  }
)

vim.lsp.enable({
  'pyright',
  'gopls',
  'ts_ls', -- javascript, typescript

  -- html, css, json, eslint: https://github.com/hrsh7th/vscode-langservers-extracted
  -- 👆裡面有 vscode-{html,css,json,eslint}-language-server 四個執行檔
  'html',
  "cssls",
  "jsonls",
  "bashls",
  "markdown_oxide",
  "clangd",
  "lua_ls",
  "sqls",      -- 用處其實不高，可以考慮移除
  "sourcekit", -- swift

  "denols"     -- deno
})

-- vim.lsp.config('svelte',
--   {
--     cmd = { "svelteserver", "--stdio" },
--     filetypes = { "svelte" },
--   })
--
-- vim.lsp.config('clangd', {
--   cmd = { "clangd", "--background-index",
--     "--clang-tidy", "--log=verbose",
--     "--fallback-style=webkit" },
--   filetypes = { "c", "cpp", "objc", "objcpp", "h" },
-- })
