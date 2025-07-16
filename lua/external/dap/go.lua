local function get_test_arguments()
  return coroutine.create(
    function(dap_run_co)
      local args = {}
      vim.ui.input(
      -- { prompt = "Args (-run=^Test_xx  -run=Test_abc  -run=Test_sql*): " }, -- 這不行
        { prompt = "Args (-test.run=^Test_xx  -test.run=Test_abc  -test.run=Test_sql*): " },
        function(input)
          args = vim.split(input or "", " ")
          coroutine.resume(dap_run_co, args)
        end
      )
    end
  )
end

local function get_build_flags()
  print("-tags=xxx -tags=foo,bar")
  return require("dap-go").get_arguments()
end


-- debug adapter
---- go
--- 當突然沒辦法debug的時候，請嘗試更新dlv
--- go install github.com/go-delve/delve/cmd/dlv@latest
--- dlv version
--- 1.25.0
require('dap-go').setup { -- https://github.com/leoluz/nvim-dap-go/blob/8763ced35b19c8dc526e04a70ab07c34e11ad064/README.md?plain=1#L46-L100
  -- Additional dap configurations can be added.
  -- dap_configurations accepts a list of tables where each entry
  -- represents a dap configuration. For more details do:
  -- :help dap-configuration
  dap_configurations = {
    -- https://github.com/leoluz/nvim-dap-go/blob/8763ced35b19c8dc526e04a70ab07c34e11ad064/lua/dap-go.lua#L103-L165
    {
      -- Must be "go" or it will be ignored by the plugin
      type = "go",
      name = "Attach remote",
      mode = "remote",
      request = "attach",
    },
    {
      type = "go",
      name = "Debug Package (Arguments)",
      request = "launch",
      program = "${fileDirname}",
      args = require("dap-go").get_arguments, -- -workDir=img/2025
    },
    {
      type = "go",
      name = "Debug Package (Build Flags & Arguments)",
      request = "launch",
      program = "${fileDirname}",
      args = require("dap-go").get_arguments,         -- -workDir=img/2025
      buildFlags = require("dap-go").get_build_flags, -- -tags=xxx -- -tags=foo,bar
    },
    {
      type = "go",
      name = "Debug test (go.mod & arguments)",
      request = "launch",
      mode = "test",
      program = "./${relativeFileDirname}",
      -- args 可以用來設定指定要執行的test就可以不用全部都執從: -test.run=^TestXXx  -- -test.run=Test_myXXX
      -- args = require("dap-go").get_arguments, -- 可行，但是提示詞只有Args
      args = get_test_arguments,
    },
    {
      type = "go",
      name = "Debug test (go.mod & arguments & tags)",
      request = "launch",
      mode = "test",
      program = "./${relativeFileDirname}",
      args = get_test_arguments,
      buildFlags = get_build_flags,
    },
  },
  -- delve configurations
  delve = {
    -- the path to the executable dlv which will be used for debugging.
    -- by default, this is the "dlv" executable on your PATH.
    path = "dlv",
    -- time to wait for delve to initialize the debug session.
    -- default to 20 seconds
    initialize_timeout_sec = 20,
    -- a string that defines the port to start delve debugger.
    -- default to string "${port}" which instructs nvim-dap
    -- to start the process in a random available port.
    -- if you set a port in your debug configuration, its value will be
    -- assigned dynamically.
    port = "${port}",
    -- additional args to pass to dlv
    args = {
      -- "-workDir", "img/2503", -- ❌ 這不是flag.Parse的那些參數，不是放這邊
    },
    -- the build flags that are passed to delve.
    -- defaults to empty string, but can be used to provide flags
    -- such as "-tags=unit" to make sure the test suite is
    -- compiled during debugging, for example.
    -- passing build flags using args is ineffective, as those are
    -- ignored by delve in dap mode.
    -- avaliable ui interactive function to prompt for arguments get_arguments
    build_flags = {
      -- "-tags=xxx", -- 建置時候的tag, 即go run -tags=xxx -- 建議在 dap_configurations 中設定避免寫死，即: require("dap-go").get_arguments
    },
    -- whether the dlv process to be created detached or not. there is
    -- an issue on delve versions < 1.24.0 for Windows where this needs to be
    -- set to false, otherwise the dlv server creation will fail.
    -- avaliable ui interactive function to prompt for build flags: get_build_flags
    detached = vim.fn.has("win32") == 0,
    -- the current working directory to run dlv from, if other than
    -- the current working directory.
    cwd = nil,
  },
  -- options related to running closest test
  tests = {
    -- enables verbosity when running the test.
    verbose = false,
  },
}
