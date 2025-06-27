-- require("dap").adapters.custome = {
--   type = 'executable',
--   command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
-- }

-- -@type vim.SystemCompleted r

---@param exe_name string
---@param param table
---@param ok_lines table 成功後的前導輸出文字
---@param opts table
local function show_run_result(exe_name, param, ok_lines, opts)
  if vim.fn.executable(exe_name) == 0 then
    return
  end
  local r = vim.system({ exe_name, unpack(param) }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ [%s] err code: %d err msg: %s", exe_name, r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  -- local text = {
  --   "file: " .. fontpath,
  --   "result: ",
  --   " ",
  --   unpack(vim.split(r.stdout, "\n"))
  -- }
  local lines = ok_lines
  for _, line in ipairs({
    '',
    string.format("cmd: %s %s", exe_name, table.concat(param, " ")),
    '',
  }) do
    table.insert(lines, line)
  end

  table.insert(lines, "stdout:")
  for _, line in ipairs(vim.split(r.stdout, "\n")) do
    table.insert(lines, line)
  end

  table.insert(lines, "stderr:") -- 有些訊息也會寫在這邊，所以也有納入
  for _, line in ipairs(vim.split(r.stderr, "\n")) do
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for _, cmd in ipairs(opts.cmds) do
    -- vim.cmd([[call matchadd('@label', '\v^\w*:')]]) -- 這樣的壞處是它是全域都有效的，不能指定buffer, 不過可以透過 :call clearmatches() 來全部清除
    vim.cmd(cmd)
  end
  vim.cmd(string.format([[call matchadd('MiniIconsOrange', '%s')]], exe_name))
end


require("dap").configurations.opentype = {
  {
    name = "convert to fontTools:ttx format",
    type = "custom",
    request = "launch",

    program = function()
      if vim.fn.executable("python") == 0 then
        return
      end

      local fontpath = vim.fn.expand("%:p") -- 獲取當前檔案的完整路徑

      -- 因為已經是確定filetype是自定的opentype所以就不做附檔名的判斷了
      -- local ext = vim.fn.expand("%:e"):lower() -- 獲取副檔名（小寫）
      -- -- 檢查是否為 ttf 或 otf 檔案
      -- if ext ~= "ttf" and ext ~= "otf" then
      --   return
      -- end

      local python_code = string.format([[
import io
import sys

from fontTools.misc.xmlWriter import XMLWriter
from fontTools.ttLib import TTFont

font = TTFont("%s")

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
writer = XMLWriter(sys.stdout, newlinestr="\n")
font._saveXML(writer)
]], fontpath)

      local r = vim.system({ "python3", "-c", python_code }):wait()
      if r.code ~= 0 then
        vim.notify(string.format("❌ fontTools.TTFont.saveXML error. err code: %d %s", r.code, r.stderr),
          vim.log.levels.WARN)
        return
      end
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_set_option_value("filetype", "ttx", { buf = buf })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
      return ""
    end
  },
  {
    name = "ots-sanitize 字型驗證器",
    type = "custom",
    request = "launch",
    program = function()
      local fontpath = vim.fn.expand("%:p")
      local ok_lines = {
        "file: " .. fontpath,
      }
      show_run_result("ots-sanitize", { fontpath },
        ok_lines,
        {
          cmds = {
            [[call matchadd('@label', '\v^\w*:')]]
          }
        }
      )
      return ""
    end
  },
  {
    name = "ots-idempotent 字型轉碼穩定性檢查器",
    type = "custom",
    request = "launch",
    program = function()
      local fontpath = vim.fn.expand("%:p")
      local ok_lines = {
        "file: " .. fontpath,
      }
      show_run_result("ots-idempotent", { fontpath },
        ok_lines,
        {
          cmds = {
            [[call matchadd('@label', '\v^\w*:')]]
          }
        }
      )
    end
  },
  {
    name = "ots-validator-checker 惡意字型驗證測試工具",
    type = "custom",
    request = "launch",
    program = function()
      local fontpath = vim.fn.expand("%:p")
      local ok_lines = {
        "file: " .. fontpath,
      }
      show_run_result("ots-validator-checker", { fontpath },
        ok_lines,
        {
          cmds = {
            [[call matchadd('@label', '\v^\w*:')]]
          }
        }
      )
    end
  },
  {
    name = "ots-side-by-side 渲染比對工具",
    type = "custom",
    request = "launch",
    program = function()
      local fontpath = vim.fn.expand("%:p")
      local ok_lines = {
        "file: " .. fontpath,
      }
      show_run_result("ots-side-by-side", { fontpath },
        ok_lines,
        {
          cmds = {
            [[call matchadd('@label', '\v^\w*:')]]
          }
        }
      )
    end
  },
  {
    name = "ots-perf 轉碼效能測試工具",
    type = "custom",
    request = "launch",
    program = function()
      local fontpath = vim.fn.expand("%:p")
      local ok_lines = {
        "file: " .. fontpath,
      }
      show_run_result("ots-perf", { fontpath },
        ok_lines,
        {
          cmds = {
            [[call matchadd('@label', '\v^\w*:')]]
          }
        }
      )
    end
  },
}
