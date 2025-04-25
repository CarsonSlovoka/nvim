local M = {}

---@return table
function M.get_encoding_list()
  -- 包含所有 :help encoding-values 中列出的編碼值和別名
  return {
    -- 8-bit 編碼
    'latin1',
    'iso-8859-2',
    'iso-8859-3',
    'iso-8859-4',
    'iso-8859-5',
    'iso-8859-6',
    'iso-8859-7',
    'iso-8859-8',
    'iso-8859-9',
    'iso-8859-10',
    'iso-8859-11',
    'iso-8859-12',
    'iso-8859-13',
    'iso-8859-14',
    'iso-8859-15',
    'koi8-r',
    'koi8-u',
    'macroman',
    'cp437',
    'cp737',
    'cp775',
    'cp850',
    'cp852',
    'cp855',
    'cp857',
    'cp860',
    'cp861',
    'cp862',
    'cp863',
    'cp865',
    'cp866',
    'cp869',
    'cp874',
    'cp1250',
    'cp1251',
    'cp1253',
    'cp1254',
    'cp1255',
    'cp1256',
    'cp1257',
    'cp1258',
    -- 雙位元組編碼
    'cp932',
    'euc-jp',
    'sjis',
    'cp949',
    'euc-kr',
    'cp936',
    'euc-cn',
    'cp950',
    'big5',
    'euc-tw',
    -- Unicode 編碼
    'utf-8',
    'ucs-2',
    'ucs-2le',
    'utf-16',
    'utf-16le',
    'ucs-4',
    'ucs-4le',
    'utf-32',
    'utf-32le',
    -- 別名
    'ansi',
    'japan',
    'korea',
    'prc',
    'chinese',
    'taiwan',
    'utf8',
    'unicode',
    'ucs2be',
    'ucs-2be',
    'ucs-4be',
    'default',

    -- 以下是我自己補的
    'gb18030',
  }
end

local json = {}

--- @return table
function json.load(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    print('open faild: ' .. filepath)
    return {}
  end

  local content = file:read('*all')
  file:close()

  return vim.json.decode(content) -- 🤔 不曉得怎麼處理失敗
end

M.json = json

return M
