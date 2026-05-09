local utils = require("utils.utils")
local dap = require("dap")

-- python
if utils.os.IsWindows then
  -- pyenv 安裝: https://github.com/CarsonSlovoka/nvim/blob/8db59ef4c3a8b36ac6cb8675978c6c464a5fc345/docs/windows.md?plain=1#L170-L207
  -- pyenv versions
  -- pyenv install 3.13.1 -- 安裝
  -- pyenv global 3.13.1 -- 切換
  -- 此時目錄: pyenv-win/shims/ 中的python 就是指3.13.1 如果切換不同的就會是不同的python版本
  vim.g.python3_host_prog = vim.fn.resolve(os.getenv("userprofile") .. "/.pyenv/pyenv-win/shims/python")

  -- 如果有問題可以用 :checkhealth 來確認
  -- Python 3 provider (optional) ~
  -- pyenv: Path: %userprofile%\.pyenv\pyenv-win\bin\pyenv.BAT
  -- pyenv: Root: %userprofile%\.pyenv\pyenv-win\
  -- Using: g:python3_host_prog = "%userprofile%/.pyenv/pyenv-win/shims/python"
  -- Executable: %userprofile%\.pyenv\pyenv-win\shims\python.BAT
  -- 👇 以下這三個是要有pip install neovim時才會出現
  -- Python version: 3.13.1
  -- pynvim version: 0.5.2
  -- OK Latest pynvim is installed.

  -- pyenv shell 3.13.1
  -- pip install neovim 💡這個很重要！
  -- 測試: python -c "import neovim; print(neovim.__file__)"
  -- %AppData%\Python\Python313\site-packages\neovim\__init__.py
else
  vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")
end

-- 實際上dap-python的setup也是有設定dap.adapters.python與dap.configurations.python: https://github.com/mfussenegger/nvim-dap-python/blob/261ce649d05bc455a29f9636dc03f8cdaa7e0e2c/lua/dap-python.lua#L218-L274
require('dap-python').setup(
-- "/usr/bin/python3" -- 如果要debug fontforge之類的要再切換, 但是/usr/bin/pip3也要安裝，但是ubuntu上這是鎖版本的
-- vim.fn.expand("~/.pyenv/shims/python3") -- 預設會自己抓
) -- https://github.com/mfussenegger/nvim-dap-python/blob/34282820bb713b9a5fdb120ae8dd85c2b3f49b51/README.md?plain=1#L62-L142


local PYTHONPATH = "/usr/local/lib/python3.13/site-packages/"
if vim.uv.os_uname().sysname == "Darwin" then
  -- fd fontforge.so -t f $(brew --prefix fontforge)
  -- export PYTHONPATH="$(brew --prefix fontforge)/lib/python3.14/site-packages/"
  local prefix = io.popen("brew --prefix fontforge"):read("*l")
  if prefix then
    PYTHONPATH = prefix .. "/lib/python3.14/site-packages/"
  end
  -- Todo: 無效，可能要透過fontforge -script的方式來啟動
end

-- 如果都倚靠day-python在windows上可能還是會遇到: command `python3` of adapter `python` exited with 9009. Run :DapShowLog to open logs
-- 所以還是要自己設定
if vim.uv.os_uname().version:match 'Windows' then -- 若非windows, 就直接用dap-python的設定即可: https://github.com/mfussenegger/nvim-dap-python/blob/261ce649d05bc455a29f9636dc03f8cdaa7e0e2c/lua/dap-python.lua#L218-L274
  -- Important: 以下dap.adapters這可行，但是更好的方式是寫成function, 可以處理不同的type, 例如executable, remote, ... 的情況
  -- dap.adapters.python = {
  --   type = 'executable',
  --   command = 'python',                -- 確保系統能抓到這個執行檔
  --   args = { '-m', 'debugpy.adapter' } -- pip install debugpy
  -- }

  -- `cd ~/.local/share/nvim/site/pack/core/opt/nvim-dap-python/ && git show -p 34282820:lua/dap-python.lua | bat -l lua -P -r 218:262`
  dap.adapters.python = function(cb, config)
    local adapter = {}
    if config.request == 'attach' then
      local port = (config.connect or config).port
      local host = (config.connect or config).host or '127.0.0.1'
      adapter = {
        type = 'server',
        port = assert(port, '`connect.port` is required for a python `attach` configuration'),
        host = host,
        -- enrich_config = enrich_config, -- 與pythonPath有關
        options = {
          source_filetype = 'python',
        }
      }
      cb(adapter)
      return
    end

    -- executable
    adapter = {
      type = 'executable',
      command = 'python',                -- 確保系統能抓到這個執行檔. 這邊是主因套件用的是python_path的變數, windows可能會抓不到，所以這邊改成python
      args = { '-m', 'debugpy.adapter' } -- pip install debugpy
    }
    cb(adapter)
  end
end

dap.adapters.python_help = function(cb, config)
  for _, tip in ipairs(config.tips) do
    print(tip)
  end
  vim.fn.setreg('"', config.tips[1]) -- 只複製第一個, 其它的可以當參考
  -- cb({}) 不cb就不會再往下
end

-- dap.configurations.python = {} -- 如果想要保留原始的配置，可以用table.insert往後增加
for _, config in ipairs({
  {
    type = "python",
    request = 'launch',
    name = "python3 <file>",
    program = "${file}",
    -- pythonPath = function() return 'python3' end
  },
  {
    type = "python",
    request = 'launch',
    name = "debug (justMyCode=false) python3 <file>",
    program = "${file}",
    justMyCode = false, -- 如此step_into才可以進入第三方的原始碼中
  },
  {
    type = "python",
    request = 'launch',
    name = "debug (justMyCode=false) python3 <file> <args>",
    program = "${file}",
    args = require("dap-go").get_arguments,
    justMyCode = false,
  },
  {
    type = 'python',
    request = 'launch',
    name = "python -m unittest my_test.TestClass",
    module = 'unittest', -- 👈 這個是單元測試的關鍵
    -- args = require("dap-go").get_arguments,
    args = utils.dap.input_arguments(
    -- python -m unittest my_test  # 對整份文件測試, my_test.py
    -- python -m unittest my_test.TestUnitest  # 僅測試class TestUnitest
      "Args: {my_test.TestClass  my_test}:"
    ),
    justMyCode = false,
  },
  {
    type = "python",
    request = 'launch',
    name = "python3 <file from telescope>",
    program = function() -- 可以回傳的型別: string, thread
      -- return "${file}"         -- 保留字, 取當前檔案路徑
      -- return "/home/xxx/my.py" -- 絕對路徑
      return coroutine.create(function(dap_run_co)
        local picker = require("external.telescope.picker")
        picker.get_file(
          {
            title = "python <file>: select input file:",
            exts = {
              "py"
            }
          },
          function(select_item)
            coroutine.resume(dap_run_co, select_item)
          end
        )
      end)
    end,
  },
  {
    type = "python",
    request = 'launch',
    name = "(linux) env:fontforge python3 <file> <args>",
    program = "${file}",
    args = require("dap-go").get_arguments,
    env = {
      -- find /usr/local -name "fontforge*.so"
      -- /usr/local/lib/python3.13/site-packages/fontforge.so
      -- /opt/homebrew/opt/fontforge/lib/python3.14/site-packages/fontforge.so
      -- PYTHONPATH = '/usr/local/lib/python3.13/site-packages/', -- 將fontforge.so的目錄提供給PYTHONPATH即可
      PYTHONPATH = PYTHONPATH,

      -- 給以下的沒用
      -- fd -t f fontforge /
      -- /usr/lib/python3/dist-packages/fontforge.cpython-312-x86_64-linux-gnu.so
      -- PYTHONPATH = '/usr/lib/python3/dist-packages/'
    },
    -- justMyCode = false, -- 加了這個也沒辦法進入fontforge的py之中，因該是因為它是與C混編的關係
  },
  {
    -- Tip: attach的使用方式，先在終端使用: `python -m debugpy --listen 2345 --wait-for-client my.py`
    type = 'python',
    request = 'attach',
    name = 'Attach to remote',
    -- args = require("dap-go").get_arguments, -- Note: attach 放參數沒用, 是在執行終端機的python -m debugpy ... 之中這邊要放參數
    connect = {
      host = '127.0.0.1',
      -- port = 2345,
      port = function()
        local port = vim.fn.input('Port: ')
        if port == "" then
          port = "2345"
        end
        return tonumber(port)
      end,
    },
    justMyCode = false,
  },
  {
    type = 'python_help',
    name = 'Attach to remote -- [help]',
    tips = {
      "python -m debugpy --listen 2345 --wait-for-client ${file}",
      "python -m debugpy --listen 2345 --wait-for-client ${file} arg1 arg2 ...",
    }
  },
  {
    type = "notepad", -- references an entry in dap.adapters --同時也是該 filetype 才會觸發
    request = 'launch',
    name = "[FOR TEST ONLY] noepad",
    program = "${file}",
  },
}) do
  table.insert(dap.configurations.python, config)
end
