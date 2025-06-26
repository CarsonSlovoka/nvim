-- require("dap").adapters.custome = {
--   type = 'executable',
--   command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
-- }

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
  }
}
