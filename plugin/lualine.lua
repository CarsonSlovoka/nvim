local ok, m = pcall(require, "lualine")
if not ok then
  vim.notify("Failed to load lualine", vim.log.levels.ERROR)
  return
end

local function oil_filename()
  local bufname = vim.api.nvim_buf_get_name(0) -- `:lua print(vim.api.nvim_buf_get_name(0))` oil:///Users/.../
  if bufname:match("^oil://") then
    local path = bufname:gsub("^oil://", "")
    -- return vim.fn.fnamemodify(path, ":~")
    return vim.fn.fnamemodify(path, ":t") -- 🤔 oil的部份不太理想, 當前好像有問題, 還是先採用: `extensions = { 'oil' }` 的方式
  end
  return string.format("%s/%s",           -- 顯示前一層目錄 + 檔名
    vim.fn.fnamemodify(bufname, ":h:t"), vim.fn.fnamemodify(bufname, ":t"
    ))
end

m.setup {
  extensions = { 'oil' }, -- 如果裝了oil.nvim, 也可以考慮這樣用, 如此lualine會顯示, 但是路徑是顯示全名
  sections = {
    lualine_c = {
      {
        'filename',             -- Tip: 預設是 'filename', 也可以用自定義函數: oil_filename
        -- 以下都是預設，其實可以直將path改成4即可
        file_status = true,     -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 4,               -- 0: Just the filename
        -- 1: Relative path
        -- 2: Absolute path
        -- 3: Absolute path, with tilde as the home directory
        -- 4: Filename and parent dir, with tilde as the home directory

        shorting_target = 40, -- Shortens path to leave 40 spaces in the window
        -- for other components. (terrible name, any suggestions?)
        symbols = {
          modified = '[+]',      -- Text to show when the file is modified.
          readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
          unnamed = '[No Name]', -- Text to show for unnamed buffers.
          newfile = '[New]',     -- Text to show for newly created file before first write
        }
      }
    },
    lualine_x = {
      -- indent settings
      function()
        local tabstop = vim.opt.tabstop:get()
        local indent = vim.fn.indent('.') -- " indent('.') 是當前列的縮進是幾個空白. 可以曉得要一口氣縮進多少
        -- return tonumber(indent) / tonumber(tabstop)
        if tonumber(indent) % tonumber(tabstop) == 0 then
          return tonumber(indent) / tonumber(tabstop)
        end
        return string.format("%.1f", tonumber(indent) / tonumber(tabstop))
      end,
      function()
        local indent_style = vim.opt_local.expandtab:get() and "Space" or "Tab"
        if indent_style == "Space" then
          local indent_size = vim.opt_local.tabstop:get()
          return indent_size .. " spaces"
        end
        return indent_style
      end,
      -- 'encoding', -- 這也可，但是預設不會顯示bomb
      {
        'encoding',
        show_bomb = true
      },
      'fileformat', 'filetype',
    },
    lualine_y = { -- progress
      -- function()
      --   return "Total Lines: " .. vim.api.nvim_buf_line_count(0)
      -- end
      "%p%% (%L)" -- 可以直接用vim的表達方式也可
    },
    -- lualine_z = { -- location
    -- }
  }
}
