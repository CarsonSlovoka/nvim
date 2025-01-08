--[[
原理，利用facitx5-remote去啟用或者停用
fcitx5-remote -help
fcitx5-remote [OPTION]
  -c inactivate input method
  -o activate input method
  [no option] display fcitx state, 0 for close, 1 for inactive, 2 for active
--]]--

local Fcitx = {
  cmd = 'fcitx5-remote' -- 比較舊版的可能是fcitx-remote
}

function Fcitx.ActiveFcitx()
  local state = tonumber(vim.fn.system(Fcitx.cmd))
  if state ~= 2 then
    vim.fn.system(Fcitx.cmd .. ' -o')
    -- print("fcitx acitve")
  end
end

function Fcitx.InActiveFcitx()
  local state = tonumber(vim.fn.system(Fcitx.cmd))
  if state == 2 then
    vim.fn.system(Fcitx.cmd .. ' -c')
    -- print("fcitx inacitve")
  end
end

function Fcitx.setup(cmd)
  Fcitx.cmd = cmd

  -- 檢查是否有fcitx指令
  if vim.fn.executable(Fcitx.cmd) ~= 1 then
    vim.notify(string.format("所提供的fcitx5命令為不可執行，請確定真的有此執行檔: which %s", Fcitx.cmd), vim.log.levels.INFO)
    return
  end

  vim.api.nvim_create_augroup("fcitx", { clear = true })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = "fcitx",
    pattern = "*", -- *.txt etc.
    callback = Fcitx.ActiveFcitx
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = "fcitx",
    pattern = "*",
    callback = Fcitx.InActiveFcitx
  })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = "fcitx",
    pattern = "[/\\?]", -- 搜尋的時候`/`, `?`
    callback = Fcitx.ActiveFcitx
  })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = "fcitx",
    pattern = "[:]", -- 打指令的時候，也切換成英文
    callback = Fcitx.InActiveFcitx
  })
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = "fcitx",
    pattern = "[/\\?]",
    callback = Fcitx.InActiveFcitx
  })

  -- print("setup fcitx success")
end

return {
  fcitx = Fcitx
}
