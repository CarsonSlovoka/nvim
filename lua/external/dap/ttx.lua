local function program_save2ttx()
  if vim.fn.executable("ttx") == 0 then
    return
  end

  if vim.bo.readonly then
    -- 代表當前的buffer可能經過修改而且是**還沒有儲檔**
    -- 如果以這種狀態去做，看的還是之前的未修改前的檔案內容，出來的就會不如遇期
    vim.notify("當前的狀態為readonly, 請考慮另儲新檔( :w xxx.ttx | e xxx.ttx )後再次執行")
    return
  end

  local ttxPath = vim.fn.expand("%:p")
  local outputPath = vim.fn.input("output filepath: ")
  -- if outputPath == "" then
  --   outputPath = vim.fn.resolve(string.format("%s/%s.otf", vim.fn.expand("%:p:h"), vim.fn.expand("%:r")))
  -- end
  local cmd
  -- https://fonttools.readthedocs.io/en/latest/ttx.html
  if outputPath ~= "" then
    cmd = { "ttx", ttxPath, "-o", outputPath }
  else
    cmd = { "ttx", ttxPath } -- 預設輸出的檔名與ttx的名稱相同，附檔名則會依據內容自動調整
    -- 如果檔案名稱已經存儲, ttx會自動加上流水號
  end
  local r = vim.system(cmd):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ fontTools.TTFont.saveXML error. err code: %d %s", r.code, r.stderr),
      vim.log.levels.WARN)
    return ""
  end
  vim.notify(string.format("✅ 指令: %q 執行成功，請查看輸出檔案", table.concat(cmd, " ")))
  if outputPath ~= "" then
    vim.cmd("e " .. outputPath)
  end
  return ""
end

require("dap").configurations.ttx = {
  {
    name = "save to xxx.{otf, ttf}",
    type = "custom",
    request = "launch",

    program = program_save2ttx,
  },
  { -- 加入這個項目只是為了不要只有一個項目(當只有一個項目時，就會直接執行該項目，所以會看不到標題)
    name = "todo",
    type = "custom",
    request = "launch",
  },
}
