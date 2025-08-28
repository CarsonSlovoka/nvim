local test_tool = vim.uv.os_uname().sysname == "windows" and "notepad" or "vi"

require("dap").adapters.notepad = { -- 名稱也可以大小寫混合
  type = 'executable',
  command = test_tool
}
require("dap").configurations.test_text = { -- 記得看的不是附檔名，而是filetype
  -- 如果只有一個執行的時候就不會看到有選單
  -- 如果有多個時會讓你選擇要用哪一個來執行
  {
    type = "notepad", -- 定義的type一定要在require("dap").adapters之中可以找到，不然會報錯
    request = 'launch',
    name = "[FOR TEST ONLY] notepad test",
    program = function()
      return vim.fn.input(
        "Path to executable: ", -- prompt
        vim.fn.getcwd() .. '/', -- default
        'file'                  -- completion
      )
    end,
  },
  {
    type = "notepad",
    request = 'launch',
    name = "[FOR TEST ONLY] notepad test 2",
    program = function()
      vim.fn.input({
        prompt = "Enter executable (e.g., python3 , firefox ): ",
        default = "powershell",
        completion = "command",
        highlight = function(input)
          print(input)
          local highlights = {}
          local keywords = { 'python', 'firefox' }
          for _, keyword in ipairs(keywords) do
            local start_pos = 0
            while true do
              local s, e = input:find(keyword, start_pos + 1, true) -- 後面的true表示plain, 避免正規式造成影響
              if not s then
                break
              end
              table.insert(highlights, {
                s - 1,
                e,
                '@label',
              })
              start_pos = s
            end
          end

          -- 💡 如果沒有sort會遇到錯誤: E5403: Chunk 2 start 7 not in range [25, 25)
          -- 也就是highlight它避需要序順來排，不然會錯，例如:
          -- ✓ {{0, 6 , @label}, {10, 16 , @label}}
          -- x {{10, 16 , @label}, {0, 6 , @label}, }
          table.sort(highlights, function(a, b) return a[1] < b[1] end)
          return highlights
        end
      })
    end,
  }
}
