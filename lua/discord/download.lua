local curl = require("plenary.curl")
local utils = require("utils.utils")

local M = {}

local TOKEN = os.getenv("DC_TOKEN")

-- https://discord.com/developers/docs/reference#api-versioning
local API_BASE = "https://discord.com/api/v10"


--- 從 Discord API 獲取訊息並下載附件
--- @param output_dir string
--- @param channel_id string
--- @param message_ids table 可以一次對很多個message都下載其附件
function M.download_attachments(output_dir, channel_id, message_ids)
  if not TOKEN or TOKEN == "" then
    vim.notify("Please set environment variable DC_TOKEN", vim.log.levels.WARN)
    return
  end

  if not utils.os.check_output_dir(output_dir) then
    vim.notify("Cannot continue because the directory is not established", vim.log.levels.WARN)
    return
  end

  for _, msg_id in ipairs(message_ids) do
    -- 確定不需要guildID

    local url = string.format("%s/channels/%s/messages/%s", API_BASE, channel_id, msg_id)
    local res = curl.get(url, {
      headers = {
        Authorization = "Bot " .. TOKEN,
        ["Content-Type"] = "application/json",
      },
    })

    if res.status ~= 200 then
      vim.notify(string.format("無法獲取訊息 %s：%s", msg_id, res.status), vim.log.levels.WARN)
      goto continue
    end

    -- 解析 JSON 回應
    local message
    if vim.json and vim.json.decode then
      message = vim.json.decode(res.body)
    else
      -- 備選方案：如果 vim.json 不可用，可以手動處理或提示用戶
      vim.notify("錯誤：Neovim 的 vim.json 模組不可用，無法解析 JSON", vim.log.levels.ERROR)
      goto continue
    end

    if not message.attachments or #message.attachments == 0 then
      vim.notify(string.format("Message %s has no attachment", msg_id), vim.log.levels.WARN)
      goto continue
    end

    -- 下載每個附件
    for _, attachment in ipairs(message.attachments) do
      -- 這邊每一個附件給的url是暫時的，有ex到期時間，之後此Link就不能再訪問
      -- print(attachment.url)
      print(string.format("Download attachment: %s", attachment.filename))
      local filepath = output_dir .. "/" .. attachment.filename
      utils.http.download_file(attachment.url, filepath)
    end

    ::continue::
  end
end

return M
