local cur_file = debug.getinfo(1, "S").source:sub(2)
local CUR_DIR = vim.fn.fnamemodify(cur_file, ":h")


--- 儲存單個 Unicode Block 的結構
--- @class UnicodeBlockEntry
--- @field start integer Unicode 範圍的起始碼點（十進位）
--- @field end_code integer Unicode 範圍的結束碼點（十進位）
--- @field name string Block 的名稱（英文）

--- UnicodeBlock 類，用於管理 Unicode Blocks 資料
--- @class UnicodeBlock
--- @field private blocks UnicodeBlockEntry[] 儲存所有 Unicode Blocks 的表
local UnicodeBlock = {}
UnicodeBlock.__index = UnicodeBlock


--- 中英文 Block 名稱對照表
--- @type table<string, {en: string, zh: string}>
local block_names = {
  ["Basic Latin"] = { zh = "基本拉丁文" },
  ["Latin-1 Supplement"] = { zh = "拉丁文補充-1" },
  ["Latin Extended-A"] = { zh = "拉丁文擴展-A" },
  ["Latin Extended-B"] = { zh = "拉丁文擴展-B" },
  ["IPA Extensions"] = { zh = "國際音標擴展" },
  ["Spacing Modifier Letters"] = { zh = "間隔修飾符字母" },
  ["Combining Diacritical Marks"] = { zh = "組合變音符號" },
  ["No_Block"] = { zh = "無區塊" }
}

-- 讓en與key名稱相同
for key, lang_obj in pairs(block_names) do
  lang_obj["en"] = key
end

--- 創建一個新的 UnicodeBlock 物件，解析指定的 Blocks 檔案
--- @return UnicodeBlock 解析 db/Blocks.txt 生成出該物件
--- @error 如果檔案無法開啟，會拋出錯誤
function UnicodeBlock.new()
  local file_path = vim.fn.fnamemodify(CUR_DIR .. "/db/Blocks.txt", ":p")
  local self = setmetatable({}, UnicodeBlock)
  self.blocks = {}

  local file = io.open(file_path, "r")
  if not file then
    error("無法開啟檔案: " .. file_path)
  end

  for line in file:lines() do
    if line:match("^#") or line:match("^%s*$") then
      goto continue
    end

    local start_code, end_code, block_name = line:match("(%x+)%.%.(%x+);%s*(.+)")
    if start_code and end_code and block_name then
      table.insert(self.blocks, {
        start = tonumber(start_code, 16),
        end_code = tonumber(end_code, 16),
        name = block_name
      })
    end
    ::continue::
  end

  file:close()
  return self
end

--- 查詢 Unicode 碼點所在的 Block 名稱
--- @param codepoint integer Unicode 碼點（十進位或十六進位字符串，例如 0x0251 或 "0251"）
--- @param lang string 語言代碼（"en" 或 "zh"）
--- @return string @Block 的名稱（根據語言返回英文或中文，若無對應翻譯則返回英文）
function UnicodeBlock:get_ucd_block(codepoint, lang)
  if not codepoint then
    return block_names["No_Block"][lang] or block_names["No_Block"].en
  end

  for _, block in ipairs(self.blocks) do
    if codepoint >= block.start and codepoint <= block.end_code then
      local name = block_names[block.name] and block_names[block.name][lang] or block.name
      return name
    end
  end

  return block_names["No_Block"][lang] or block_names["No_Block"].en
end

return UnicodeBlock
