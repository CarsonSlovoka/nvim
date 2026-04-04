local function install_image()
  -- 如果是在 kitty 終端機啟動，就會有這個環境變數
  if os.getenv("KITTY_PID") == nil then
    return
  end
  -- print("Running in Kitty terminal")

  local ok, _ = pcall(require, "image")
  if not ok then
    vim.notify("Failed to load image", vim.log.levels.WARN)
    return
  end

  -- 啟動kitty後，如果查看markdown沒有看到圖片
  -- 1. 關閉nvim後，啟動kitty先嘗試看看圖片是否能正常顯示: `kitty +kitten icat https://sw.kovidgoyal.net/kitty/_static/kitty.svg`
  -- 2. 如果有看到，那麼可以再該markdown文件用 :e 重新載入頁面應該就會出現
  local config = {
    backend = "kitty",
    -- processor 的magick_cli, magick_rock 不是指執行檔，而是image.nvim裡面的子lua腳本
    -- 如果用的是magick_cli只需要convert, identify兩個執行檔即可: https://github.com/3rd/image.nvim/blob/4c51d6202628b3b51e368152c053c3fb5c5f76f2/lua/image/processors/magick_cli.lua#L3-L10
    -- convert, identify 都在裝完 imagemagick 就會取得
    processor = "magick_cli", -- or "magick_rock"
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = true,
        only_render_image_at_cursor_mode = "inline", -- popup, inline
        floating_windows = false,                    -- if true, images will be rendered in floating markdown windows
        filetypes = { "markdown", "vimwiki" },       -- markdown extensions (ie. quarto) can go here
      },
      neorg = {
        enabled = true,
        filetypes = { "norg" },
      },
      typst = {
        enabled = true,
        filetypes = { "typst" },
      },
      html = {
        enabled = false,
      },
      css = {
        enabled = false,
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,    -- toggles images when windows are overlapped
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
    editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
    tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
    hijack_file_patterns = {
      "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif",
      "*.ico" -- 👈 這個會影響到 gf 時候是否能看到, 而markdown中的image連結則不受此影響，沒有加也看的到
    },        -- render image files as images when opened
  }
  require("image").setup(config)


  vim.api.nvim_create_user_command("ImageToggle",
    function()
      if require("image").is_enabled() then
        require("image").disable()
      else
        require("image").enable()
      end
      vim.notify("image.nvim is_enabled: " .. tostring(require("image").is_enabled()), vim.log.levels.INFO)
    end,
    {
      nargs = 0,
      desc = "image.nvim toggle"
    }
  )
  vim.api.nvim_create_user_command("DisplayImageSettings",
    function(args)
      -- TIP: 可透過 :lua print(vim.inspect(require("image").get_images())) 查看圖片，以及瞭解設定

      local cfg = utils.cmd.get_cmp_config(args.fargs)
      local markdown_config = config.integrations.markdown

      ---@type boolean
      local at_cursor
      if cfg["at_cursor"] == "toggle" then
        at_cursor = not markdown_config.only_render_image_at_cursor
      elseif cfg["at_cursor"] then
        at_cursor = cfg["at_cursor"] == "1"
      else
        at_cursor = true
      end

      ---@type string "inline" or "popup"
      local cursor_mode
      if not at_cursor and cfg["at_cursor"] ~= nil then
        -- 只有變成inline時可以全部顯示
        cursor_mode = "inline"
      else
        cursor_mode = cfg["cursor_mode"] or "inline"
      end

      markdown_config.only_render_image_at_cursor = at_cursor

      if cursor_mode == "inline" or cursor_mode == "popup" then
        markdown_config.only_render_image_at_cursor_mode = cursor_mode
      else
        vim.api.nvim_echo({
          { '❌ cursor_mode should be ', "Normal" },
          { 'inline', '@label' },
          { ' or ', "Normal" },
          { 'popup', '@label' },
        }, false, {})
      end


      if cfg["enabled"] then
        -- WARN: 直接改此設定值不能從disabled變成enable, 所以後面還需要調用 enable() 或 disable
        if cfg["enabled"] == "toggle" then
          markdown_config.enabled = not markdown_config.enabled
        else
          markdown_config.enabled = cfg["enabled"] == "1" or false
        end
      end

      for _, key in ipairs({ "max_height", "max_width" }) do
        if cfg[key] then
          config[key] = cfg[key] == "nil" and nil or tonumber(cfg[key])
        end
      end

      -- 目前image.nvim似乎沒有提供其它的config可以再改裡面的設定，所以只能重新setup
      -- print(vim.inspect(config))

      if cfg["enabled"] then
        if markdown_config.enabled then
          require("image").enable()
        else
          require("image").disable()
        end
      end

      require("image").setup(config)
    end,
    {
      nargs = '*',
      desc = "image.nvim.setup(...)",
      complete = function(arg_lead, cmd_line)
        local comps = {}
        local argc = #(vim.split(cmd_line, '%s+')) - 1
        local prefix, suffix = arg_lead:match('^(.-)=(.*)$')

        -- 使得已經輸入過的選項，不會再出現
        local exist_comps = {}
        if argc > 1 then
          for _, key in ipairs(vim.split(cmd_line, '%s+')) do
            local k, _ = key:match('^(.-)=(.*)$')
            if k then
              exist_comps[k .. "="] = true
            end
          end
        end

        if not prefix then
          suffix = arg_lead
          prefix = ''
        end
        local need_add_prefix = true
        if argc == 0 or not arg_lead:match('=') then
          comps = vim.tbl_filter(function(item) return not exist_comps[item] end, -- 過濾已輸入過的選項
            {
              'enabled=', 'at_cursor=', 'cursor_mode=',
              'max_width=', 'max_height=',
            }) -- 全選項

          need_add_prefix = false
        elseif prefix == "at_cursor" or prefix == "enabled" then
          comps = {
            "1",
            "0",
            "toggle",
          }
        elseif prefix == "cursor_mode" then
          comps = {
            "popup",
            "inline",
          }
        elseif prefix == "max_width" or prefix == 'max_height' then
          comps = { -- %
            "nil",
            '5',
            '20',
            '50',
          }
        end
        if need_add_prefix then
          for i, comp in ipairs(comps) do
            comps[i] = prefix .. "=" .. comp
          end
        end

        local input = need_add_prefix and prefix .. "=" .. suffix or suffix
        -- return vim.tbl_filter(function(item) return vim.startswith(item, input) end, comps) -- 比較嚴格的匹配
        return vim.tbl_filter(function(item) return item:match(input) end, comps) -- 改用match比較自由
      end
    }
  )
end

vim.defer_fn(function()
  vim.pack.add({ "https://github.com/3rd/image.nvim" })
  install_image()
end, 1000)
