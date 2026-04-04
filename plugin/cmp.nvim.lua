local array = require("utils.array")

local function install_cmp_list()
  local ok, m = pcall(require, "cmp-list")
  if not ok then
    vim.notify("Failed to load cmp-list", vim.log.levels.ERROR)
    return
  end

  m.setup({
    presets = function(
    -- default_config
    )
      return m.deep_merge({}, {
        _global = array.Merge(
          require('external.cmp-list.nvim-cmd'), -- vim中的command相關 :
          require('external.cmp-list.tool'),
          require('external.cmp-list.emoji')
        ),
        sh = array.Merge(
          require('external.cmp-list.sh'),
          require('external.cmp-list.notify')
        ),
        lua = array.Merge(
          require('external.cmp-list.lua'),
          require('external.cmp-list.vim-fn')
        ),
        markdown = array.Merge(
          require('external.cmp-list.markdown')
        ),
      })
    end
  })

  -- 如果有需要可以用以下的方式在不同的lua檔案新增自己要的內容
  -- m.config.presets["text"] = utils.array.Merge(
  --   {
  --     { word = 'a123', kind = "test" },
  --   }
  -- )
  -- m.config.presets["_global"] = utils.array.Merge(
  --   m.config.presets._global,
  --   {
  --     { word = 'test12345', kind = "abcd" },
  --   }
  -- )

  -- 🧙 👇 可以用以下的方式在自定的lua檔案新增，例如: my-customize 新增自定義的嘸蝦米查找列表
  -- require("cmp-list").config.presets["_global"] = require("utils.utils").array.Merge(
  --   require("cmp-list").config.presets._global,
  --   require('external.cmp-list.boshiamy').setup({ { "觀察", "rmr nja" }, { "觀看", "rmr hmo" }, })
  -- )
  -- print(vim.inspect(m.config.presets["_global"]))

  local mWindow = require("cmp-list.window")
  vim.keymap.set(
    "n",
    "<Leader>p",
    mWindow.toggle_floating_window,
    {
      desc = "toogle cmp-list preview window",
      noremap = true,
      silent = true
    }

  )
  vim.cmd("SetCmpListEnablePreviewWindow 0")
end

vim.defer_fn(function()
  vim.pack.add({ "https://github.com/CarsonSlovoka/cmp.nvim" })
  install_cmp_list()
end, 500)
