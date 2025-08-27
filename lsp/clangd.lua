-- https://github.com/neovim/nvim-lspconfig/blob/9ae789e/doc/configs.md#clangd
-- https://gist.github.com/gelldur/d7bc3ea226aebcf8cc879df1e8524236
-- https://clang.llvm.org/docs/ClangFormatStyleOptions.html

-- 格式化不與vim.o.shiftwidth有關，而是要吃.clang-format或者額外取代


-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/clangd.lua
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/clangd.lua


---@brief
---
--- https://clangd.llvm.org/installation.html
---
--- - **NOTE:** Clang >= 11 is recommended! See [#23](https://github.com/neovim/nvim-lspconfig/issues/23).
--- - If `compile_commands.json` lives in a build directory, you should
---   symlink it to the root of your source tree.
---   ```
---   ln -s /path/to/myproject/build/compile_commands.json /path/to/myproject/
---   ```
--- - clangd relies on a [JSON compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
---   specified as compile_commands.json, see https://clangd.llvm.org/installation#compile_commandsjson

-- https://clangd.llvm.org/extensions.html#switch-between-sourceheader
local function switch_source_header(bufnr, client)
  local method_name = 'textDocument/switchSourceHeader'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify(('method %s is not supported by any servers active on the current buffer'):format(method_name))
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, result)
    if err then
      error(tostring(err))
    end
    if not result then
      vim.notify('corresponding file cannot be determined')
      return
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

local function symbol_info(bufnr, client)
  local method_name = 'textDocument/symbolInfo'
  ---@diagnostic disable-next-line:param-type-mismatch
  if not client or not client:supports_method(method_name) then
    return vim.notify('Clangd client not found', vim.log.levels.ERROR)
  end
  local win = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  ---@diagnostic disable-next-line:param-type-mismatch
  client:request(method_name, params, function(err, res)
    if err or #res == 0 then
      -- Clangd always returns an error, there is no reason to parse it
      return
    end
    local container = string.format('container: %s', res[1].containerName) ---@type string
    local name = string.format('name: %s', res[1].name) ---@type string
    vim.lsp.util.open_floating_preview({ name, container }, '', {
      height = 2,
      width = math.max(string.len(name), string.len(container)),
      focusable = false,
      focus = false,
      title = 'Symbol Info',
    })
  end, bufnr)
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

---@type vim.lsp.Config
return {
  cmd = {
    -- https://manpages.ubuntu.com/manpages/noble/man1/clangd-18.1.html
    -- 強列建議自己在專案下建立 `.clang-format` 的檔案在去設定該專案用的格式
    -- 透過BaseOnStyle可以設定所有沒有被定義到的項目要參考所一個設定，共有LLVM, Google, WebKit, GNU, WebKit, ...
    -- BasedOnStyle: https://clang.llvm.org/docs/ClangFormatStyleOptions.html#basedonstyle
    -- "--fallback-style=WebKit", -- https://www.webkit.org/code-style-guidelines/
    -- IncludeBlocks -- https://clang.llvm.org/docs/ClangFormatStyleOptions.html#includeblocks 可以設定include是要如何被格式化
    'clangd'
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    'configure.ac', -- AutoTools
    '.git',
  },
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { 'utf-8', 'utf-16' },
  },
  ---@param init_result ClangdInitializeResult
  on_init = function(client, init_result)
    if init_result.offsetEncoding then
      client.offset_encoding = init_result.offsetEncoding
    end
  end,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
      switch_source_header(bufnr, client)
    end, { desc = 'Switch between source/header' })

    vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdShowSymbolInfo', function()
      symbol_info(bufnr, client)
    end, { desc = 'Show symbol info' })

    -- 結尾多餘的空白確定這樣設定已經可以自動清除，因此不需要再設定
    -- -- 也可以加到這邊: https://github.com/CarsonSlovoka/nvim/blob/7089ab7cf0e95d6e5663b357a742eff55ddb208d/lua/config/autocmd.lua#L552-L558 但是會比較亂，要額外新增if的判斷
    -- vim.api.nvim_create_autocmd("BufWritePre", {
    --   buffer = bufnr,
    --   callback = function()
    --     -- 確定用clang-format也無法將結尾多的空白移除(至少在Clang 22.0.0是如此): https://clang.llvm.org/docs/ClangFormatStyleOptions.html
    --     -- https://stackoverflow.com/a/54486390/9935654
    --     vim.cmd([[%s/\s\+$//e]])
    --   end,
    --   { desc = "Clear the extra space at the end" }
    -- })
  end,
}
