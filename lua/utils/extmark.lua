local ns_id = vim.api.nvim_create_namespace('my_conceal_hello_world')
local function set_hello_world_conceal()
  local bufnr = vim.api.nvim_get_current_buf() -- 獲取當前緩衝區編號

  -- 清除之前的 extmark，避免重複
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  if vim.fn.mode() ~= "n" then
    return -- 不設定任何的conceal，而因為前面已經clear_namespace，所以之前如果已經有加的項目也會被解開
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local start_col = 0
    while true do
      local s, e = line:find("hello world", start_col + 1)
      if not s then
        -- 找不到就結束
        break
      end

      -- 使用 extmark 設定 conceal
      vim.api.nvim_buf_set_extmark(bufnr,
        ns_id,
        lnum - 1,
        s - 1,
        {
          end_col = e,
          conceal = "🎉",
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
    desc = "用nvim_buf_set_extmark中的conceal來替換「顯示」的文字(僅影響顯示內容不變)",
    pattern = "*",
    callback = function()
      set_hello_world_conceal()
    end,
  }
)
