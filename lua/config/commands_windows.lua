local utils = require("utils.utils")


if not utils.os.IsWindows then
  return
end

vim.api.nvim_create_user_command("System32Tool",
  function(args)
    -- table.concat({}, #args.fargs)) -- table.concat(table, start, end) -- 就算start > #table, end > start 這些都沒關係
    -- unpack( table, [start], [end])
    local cmd_args = { unpack(args.fargs, 2) }
    local run_cmd = string.format("%s %s", args.fargs[1], table.concat(cmd_args, " "))
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print(timestamp .. " " .. run_cmd)
    vim.fn.system(run_cmd)
  end,
  {
    nargs = "+",
    desc = "執行 C:/Windows/System32/ 的應用程式",
    complete = function(arg_lead, cmd_line)
      local argc = #(vim.split(cmd_line, "%s+")) - 1

      if argc > 1 then
        return {} -- 自定義參數
      end

      local tools = {
        -- exeName, alias...
        { "SystemPropertiesProtection", { "SetEnv" } },
      }
      local comps = {}

      for _, item in ipairs(tools) do
        local exe = item[1]

        local found = false
        if string.find(exe, arg_lead, 1, true) then
          table.insert(comps, exe)
          found = true
        end

        if not found then
          for _, alias in ipairs(item[2]) do
            if string.find(alias:lower(), arg_lead:lower(), 1, true) -- 1 開始索引, plain不使用正則式
            then
              table.insert(comps, exe)
            end
          end
        end
      end

      return comps
    end
  }
)
