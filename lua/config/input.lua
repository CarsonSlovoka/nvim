--[[
原理，利用facitx5-remote去啟用或者停用
fcitx5-remote -help
fcitx5-remote [OPTION]
  -c inactivate input method
  -o activate input method
  [no option] display fcitx state, 0 for close, 1 for inactive, 2 for active

顯示出當前輸入法的名稱，也就是取得<imname>
fcitx5-remote -n
 keyboard-us
 boshiamy
--]] --

local Fcitx = {
  cmd = 'fcitx5-remote' -- 比較舊版的可能是fcitx-remote
}

function Fcitx.ActiveFcitx()
  local state = tonumber(vim.fn.system(Fcitx.cmd))
  if state ~= 2 then
    -- 採取的策略是統一換回英文，如果有需要在自己使用shift+ctrl去切換
    -- 有寫與沒寫的差異是至少這樣可以確定一開始是英文, shift+ctrl可再切換成其它語言
    -- 如果沒有寫，一開始無法確定語言，如果當時是boshiamy，那麼進入後還是boshimay

    -- vim.fn.system(Fcitx.cmd .. ' -o') -- 可行，但是我們希望一開始進入的時候是使用英文，之後可以按下shift切換成自己要的輸入法
    -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<S-Space><BS>", true, false, true), "n") 沒用，要單獨按下shift才會有用
    -- vim.fn.system(Fcitx.cmd .. ' -s keyboard-us -o') -- 不需要這樣
    vim.fn.system(Fcitx.cmd .. ' -s keyboard-us') -- -s 如果是指定非keyboard-us，例如boshiamy，即便目前是inActive的也會自動激活
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
