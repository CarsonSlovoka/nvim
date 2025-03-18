local M = {}

-- M.set_conceal({id="my_conceal", patterns={"hello", "world"}, conceal="🎉"})
function M.set_conceal(config)
  local ns_id = vim.api.nvim_create_namespace(config.id)
  local patterns = config.patterns
  local conceal_char = config.conceal

  local function _set_conceal()
    local bufnr = vim.api.nvim_get_current_buf()

    -- 清除之前的 extmark
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    if vim.fn.mode() ~= "n" then
      return -- 不設定任何的conceal，而因為前面已經clear_namespace，所以之前如果已經有加的項目也會被解開
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for lnum, line in ipairs(lines) do
      local start_col = 0
      while true do
        -- 對每個 pattern 進行匹配
        local matched = false
        local s, e

        for _, pattern in ipairs(patterns) do
          s, e = line:find(pattern, start_col + 1)
          if s then
            matched = true
            break
          end
        end

        if not matched then
          break
        end

        -- 使用 extmark 設定 conceal
        vim.api.nvim_buf_set_extmark(bufnr,
          ns_id,
          lnum - 1,
          s - 1,
          {
            end_col = e,
            conceal = conceal_char,
          }
        )
        start_col = e
      end
    end

    vim.opt_local.conceallevel = 2    -- 完全隱藏
    vim.opt_local.concealcursor = "n" -- cursor在n的時候會用conceal的項目來隱藏，但是如果要在整個insert下解開，靠這個還是不夠
  end

  vim.api.nvim_create_autocmd(
    {
      "BufEnter", "TextChanged", "TextChangedI",
      "ModeChanged" -- 當有任何的轉換，例如: normal > insert, insert > command, ... 都會觸發
    },
    {
      desc = "用nvim_buf_set_extmark中的conceal來替換文字",
      pattern = "*",
      callback = function()
        _set_conceal()
      end,
    }
  )
end

return M
