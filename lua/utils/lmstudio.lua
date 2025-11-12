local M = {}

--- @class ChatOptions
--- @field port? string   -- 伺服器 port，預設 "1234"
--- @field debug? boolean -- 是否開啟 debug 模式
-- ~~--- @field attachments? table<string>  -- 欲上傳的檔案路徑清單~~

--- 發送 POST 請求到本機模型，回傳優化後的文字（同步）
---@param model string  name for example: `openai/gpt-oss-20b`
---@param content string 被優化的程式碼（單行或多行，已經用 \n 拼接）
---@param opt ChatOptions?
---@return string|nil result 成功時回傳文字，失敗時 `nil`
function M.chat(model, content, opt)
  opt = opt or {}
  local port = opt.port or "1234"

  -- local attachments = {}
  -- if opt.attachments then
  --   -- print(vim.inspect(opt.attachments))
  --   for _, filepath in ipairs(opt.attachments) do
  --     local file = io.open(vim.fn.expand(filepath), "r")
  --     if not file then
  --       vim.notify("Failed to read file " .. filepath, vim.log.levels.ERROR)
  --     else
  --       local text = file:read("*a")
  --       table.insert(attachments, {
  --         name = vim.fn.fnamemodify(filepath, ":t"), -- 僅抓檔案名稱
  --         data = vim.base64.encode(text)
  --       })
  --       file:close()
  --     end
  --   end
  -- end

  local json_body = vim.json.encode({
    model    = model,
    messages = {
      {
        role = "user",
        content = content,
        -- attachments = #attachments > 0 and attachments or nil,
      }
    },
  })

  -- print(vim.inspect(json_body))
  -- if opt.debug then return "" end

  -- Tip: https://lmstudio.ai/docs/developer/openai-compat/structured-output

  -- curl -X POST http://127.0.0.1:1234/v1/chat/completions \
  --   --header "Content-Type: application/json" \
  --   --data-raw '{
  --      "model": "openai/gpt-oss-20b",
  --      "messages": [
  --        {
  --        "role": "user",
  --        "content": "what is hello\nworld"
  --      }
  --    ]
  --   }'


  -- ❌ ~~附件的格式~~ 目前不支援這種方式
  -- {
  --   "model": "...",
  --   "messages": [
  --     {
  --       "role":"user",
  --       "content":"...",
  --       "attachments":[
  --         {"name":"foo.txt","data":"<base64 string>"},
  --         {"name":"bar.png","data":"<base64 string>"}
  --       ]
  --     }
  --   ]
  -- }

  local args = {
    "-X", "POST",
    string.format("http://127.0.0.1:%s/v1/chat/completions", port),
    "--header", "Content-Type: application/json", -- -H
    "--data-raw", json_body,                      -- -d
  }

  -- 建立 pipe 用來接收 stdout
  local pipe = vim.loop.new_pipe(false)
  local data_chunks = {}

  -- spawn 的 callback 會在子進程結束時呼叫
  local handle, err = vim.loop.spawn(
    "curl",
    {
      args  = args,
      stdio = { nil, pipe, nil }, -- stdin=nil, stdout=pipe, stderr=nil
    },
    function(exit_code)
      pipe:close() -- 先關閉 pipe，然後子進程結束
      if exit_code ~= 0 then
        vim.notify("curl exited with code " .. exit_code, vim.log.levels.WARN)
      end
    end
  )

  if not handle then
    vim.notify("Failed to spawn curl: " .. err, vim.log.levels.ERROR)
    return nil
  end

  -- 讀取 stdout 的 data 事件，累積到 `data_chunks`
  pipe:read_start(function(er, chunk)
    if er then
      vim.notify("pipe read error: " .. er, vim.log.levels.ERROR)
    elseif chunk then
      table.insert(data_chunks, chunk)
    else
      -- EOF，停止讀取
      pipe:read_stop() -- <‑‑ 這裡改成 read_stop()
    end
  end)

  -- 阻塞等待子進程結束 (同步)
  vim.loop.run()

  local resp = table.concat(data_chunks)
  if resp == "" then
    vim.notify("Empty response from curl", vim.log.levels.ERROR)
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, resp)
  if not ok then
    vim.notify("JSON decode error: " .. decoded, vim.log.levels.ERROR)
    return nil
  end

  if opt.debug then
    print(vim.inspect(decoded))
  end

  if decoded.error then
    -- 可能是模型名稱打錯之類的
    vim.notify("❌ " .. vim.inspect(decoded), vim.log.levels.ERROR)
    return nil
  end

  if #decoded.choices == 1 then
    return decoded.choices[1].message.content
  end

  -- reasoning 會像是AI的思路, 也許會有幫助
  local result = ""
  for i in ipairs(decoded.choices) do
    result = result .. "📌 Part " .. i .. "\n" ..
        "🟧 content\n" .. decoded.choices[i].message.content .. "\n" ..
        "🟧 reasoning\n" .. decoded.choices[i].message.reasoning
  end
  return result
end

return M
