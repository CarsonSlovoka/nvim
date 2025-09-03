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
--- 參考: db/Blocks.txt
---
--- @type table<string, {en: string, zh: string}>
local block_names = {
  ["Basic Latin"] = { zh = "基本拉丁文" },
  ["Latin-1 Supplement"] = { zh = "拉丁文補充-1" },
  ["Latin Extended-A"] = { zh = "拉丁文擴展-A" },
  ["Latin Extended-B"] = { zh = "拉丁文擴展-B" },
  ["IPA Extensions"] = { zh = "國際音標擴展" },
  ["Spacing Modifier Letters"] = { zh = "間隔修飾符字母" },
  ["Combining Diacritical Marks"] = { zh = "組合變音符號" },
  ["Greek and Coptic"] = { zh = "希臘文與科普特文" },
  ["Cyrillic"] = { zh = "西里爾文" },
  ["Cyrillic Supplement"] = { zh = "西里爾文補充" },
  ["Armenian"] = { zh = "亞美尼亞文" },
  ["Hebrew"] = { zh = "希伯來文" },
  ["Arabic"] = { zh = "阿拉伯文" },
  ["Syriac"] = { zh = "敘利亞文" },
  ["Arabic Supplement"] = { zh = "阿拉伯文補充" },
  ["Thaana"] = { zh = "塔納文" },
  ["NKo"] = { zh = "恩科文" },
  ["Samaritan"] = { zh = "撒瑪利亞文" },
  ["Mandaic"] = { zh = "曼達文" },
  ["Syriac Supplement"] = { zh = "敘利亞文補充" },
  ["Arabic Extended-A"] = { zh = "阿拉伯文擴展-A" },
  ["Devanagari"] = { zh = "天城文" },
  ["Bengali"] = { zh = "孟加拉文" },
  ["Gurmukhi"] = { zh = "古木基文" },
  ["Gujarati"] = { zh = "古吉拉特文" },
  ["Oriya"] = { zh = "奧里亞文" },
  ["Tamil"] = { zh = "泰米爾文" },
  ["Telugu"] = { zh = "泰盧固文" },
  ["Kannada"] = { zh = "坎納達文" },
  ["Malayalam"] = { zh = "馬拉雅拉姆文" },
  ["Sinhala"] = { zh = "僧伽羅文" },
  ["Thai"] = { zh = "泰文" },
  ["Lao"] = { zh = "老撾文" },
  ["Tibetan"] = { zh = "藏文" },
  ["Myanmar"] = { zh = "緬甸文" },
  ["Georgian"] = { zh = "格魯吉亞文" },
  ["Hangul Jamo"] = { zh = "韓文字母" },
  ["Ethiopic"] = { zh = "埃塞俄比亞文" },
  ["Ethiopic Supplement"] = { zh = "埃塞俄比亞文補充" },
  ["Cherokee"] = { zh = "切羅基文" },
  ["Unified Canadian Aboriginal Syllabics"] = { zh = "加拿大原住民統一音節" },
  ["Ogham"] = { zh = "歐甘文" },
  ["Runic"] = { zh = "盧恩文" },
  ["Tagalog"] = { zh = "他加祿文" },
  ["Hanunoo"] = { zh = "哈努諾文" },
  ["Buhid"] = { zh = "布希德文" },
  ["Tagbanwa"] = { zh = "塔格巴努瓦文" },
  ["Khmer"] = { zh = "高棉文" },
  ["Mongolian"] = { zh = "蒙古文" },
  ["Unified Canadian Aboriginal Syllabics Extended"] = { zh = "加拿大原住民統一音節擴展" },
  ["Limbu"] = { zh = "林布文" },
  ["Tai Le"] = { zh = "傣仂文" },
  ["New Tai Lue"] = { zh = "新傣仂文" },
  ["Khmer Symbols"] = { zh = "高棉符號" },
  ["Buginese"] = { zh = "布吉文" },
  ["Tai Tham"] = { zh = "蘭納文" },
  ["Combining Diacritical Marks Extended"] = { zh = "組合變音符號擴展" },
  ["Balinese"] = { zh = "巴厘文" },
  ["Sundanese"] = { zh = "巽他文" },
  ["Batak"] = { zh = "巴塔克文" },
  ["Lepcha"] = { zh = "雷布查文" },
  ["Ol Chiki"] = { zh = "桑塔利文" },
  ["Cyrillic Extended-C"] = { zh = "西里爾文擴展-C" },
  ["Georgian Extended"] = { zh = "格魯吉亞文擴展" },
  ["Sundanese Supplement"] = { zh = "巽他文補充" },
  ["Vedic Extensions"] = { zh = "吠陀擴展" },
  ["Phonetic Extensions"] = { zh = "語音擴展" },
  ["Phonetic Extensions Supplement"] = { zh = "語音擴展補充" },
  ["Combining Diacritical Marks Supplement"] = { zh = "組合變音符號補充" },
  ["Latin Extended Additional"] = { zh = "拉丁文擴展附加" },
  ["Greek Extended"] = { zh = "希臘文擴展" },
  ["General Punctuation"] = { zh = "通用標點" },
  ["Superscripts and Subscripts"] = { zh = "上標與下標" },
  ["Currency Symbols"] = { zh = "貨幣符號" },
  ["Combining Diacritical Marks for Symbols"] = { zh = "符號用組合變音符號" },
  ["Letterlike Symbols"] = { zh = "字母樣符號" },
  ["Number Forms"] = { zh = "數字形式" },
  ["Arrows"] = { zh = "箭頭" },
  ["Mathematical Operators"] = { zh = "數學運算符" },
  ["Miscellaneous Technical"] = { zh = "雜項技術符號" },
  ["Control Pictures"] = { zh = "控制圖片" },
  ["Optical Character Recognition"] = { zh = "光學字符識別" },
  ["Enclosed Alphanumerics"] = { zh = "封閉字母數字" },
  ["Box Drawing"] = { zh = "框繪製" },
  ["Block Elements"] = { zh = "塊元素" },
  ["Geometric Shapes"] = { zh = "幾何形狀" },
  ["Miscellaneous Symbols"] = { zh = "雜項符號" },
  ["Dingbats"] = { zh = "裝飾符號" },
  ["Miscellaneous Mathematical Symbols-A"] = { zh = "雜項數學符號-A" },
  ["Supplemental Arrows-A"] = { zh = "補充箭頭-A" },
  ["Braille Patterns"] = { zh = "盲文圖案" },
  ["Supplemental Arrows-B"] = { zh = "補充箭頭-B" },
  ["Miscellaneous Mathematical Symbols-B"] = { zh = "雜項數學符號-B" },
  ["Supplemental Mathematical Operators"] = { zh = "補充數學運算符" },
  ["Miscellaneous Symbols and Arrows"] = { zh = "雜項符號與箭頭" },
  ["Glagolitic"] = { zh = "格拉哥里字母" },
  ["Latin Extended-C"] = { zh = "拉丁文擴展-C" },
  ["Coptic"] = { zh = "科普特文" },
  ["Georgian Supplement"] = { zh = "格魯吉亞文補充" },
  ["Tifinagh"] = { zh = "提菲納文" },
  ["Ethiopic Extended"] = { zh = "埃塞俄比亞文擴展" },
  ["Cyrillic Extended-A"] = { zh = "西里爾文擴展-A" },
  ["Supplemental Punctuation"] = { zh = "補充標點" },
  ["CJK Radicals Supplement"] = { zh = "中日韓部首補充" },
  ["Kangxi Radicals"] = { zh = "康熙部首" },
  ["Ideographic Description Characters"] = { zh = "表意文字描述字符" },
  ["CJK Symbols and Punctuation"] = { zh = "中日韓符號與標點" },
  ["Hiragana"] = { zh = "平假名" },
  ["Katakana"] = { zh = "片假名" },
  ["Bopomofo"] = { zh = "注音符號" },
  ["Hangul Compatibility Jamo"] = { zh = "韓文兼容字母" },
  ["Kanbun"] = { zh = "漢文" },
  ["Bopomofo Extended"] = { zh = "注音符號擴展" },
  ["CJK Strokes"] = { zh = "中日韓筆畫" },
  ["Katakana Phonetic Extensions"] = { zh = "片假名語音擴展" },
  ["Enclosed CJK Letters and Months"] = { zh = "封閉中日韓字母與月份" },
  ["CJK Compatibility"] = { zh = "中日韓兼容" },
  ["CJK Unified Ideographs Extension A"] = { zh = "中日韓統一表意文字擴展A" },
  ["Yijing Hexagram Symbols"] = { zh = "易經六十四卦符號" },
  ["CJK Unified Ideographs"] = { zh = "中日韓統一表意文字" },
  ["Yi Syllables"] = { zh = "彝文音節" },
  ["Yi Radicals"] = { zh = "彝文部首" },
  ["Lisu"] = { zh = "傈僳文" },
  ["Vai"] = { zh = "瓦伊文" },
  ["Cyrillic Extended-B"] = { zh = "西里爾文擴展-B" },
  ["Bamum"] = { zh = "巴姆文" },
  ["Modifier Tone Letters"] = { zh = "修飾聲調字母" },
  ["Latin Extended-D"] = { zh = "拉丁文擴展-D" },
  ["Syloti Nagri"] = { zh = "錫爾赫特文" },
  ["Common Indic Number Forms"] = { zh = "通用印度數字形式" },
  ["Phags-pa"] = { zh = "八思巴文" },
  ["Saurashtra"] = { zh = "索拉什特拉文" },
  ["Devanagari Extended"] = { zh = "天城文擴展" },
  ["Kayah Li"] = { zh = "克耶李文" },
  ["Rejang"] = { zh = "瑞璋文" },
  ["Hangul Jamo Extended-A"] = { zh = "韓文字母擴展-A" },
  ["Javanese"] = { zh = "爪哇文" },
  ["Myanmar Extended-B"] = { zh = "緬甸文擴展-B" },
  ["Cham"] = { zh = "占文" },
  ["Myanmar Extended-A"] = { zh = "緬甸文擴展-A" },
  ["Tai Viet"] = { zh = "傣越文" },
  ["Meetei Mayek Extensions"] = { zh = "曼尼普爾文擴展" },
  ["Ethiopic Extended-A"] = { zh = "埃塞俄比亞文擴展-A" },
  ["Latin Extended-E"] = { zh = "拉丁文擴展-E" },
  ["Cherokee Supplement"] = { zh = "切羅基文補充" },
  ["Meetei Mayek"] = { zh = "曼尼普爾文" },
  ["Hangul Syllables"] = { zh = "韓文音節" },
  ["Hangul Jamo Extended-B"] = { zh = "韓文字母擴展-B" },
  ["High Surrogates"] = { zh = "高位代理" },
  ["High Private Use Surrogates"] = { zh = "高位私有使用代理" },
  ["Low Surrogates"] = { zh = "低位代理" },
  ["Private Use Area"] = { zh = "私有使用區" },
  ["CJK Compatibility Ideographs"] = { zh = "中日韓兼容表意文字" },
  ["Alphabetic Presentation Forms"] = { zh = "字母表現形式" },
  ["Arabic Presentation Forms-A"] = { zh = "阿拉伯文表現形式-A" },
  ["Variation Selectors"] = { zh = "變體選擇符" },
  ["Vertical Forms"] = { zh = "豎排形式" },
  ["Combining Half Marks"] = { zh = "組合半標記" },
  ["CJK Compatibility Forms"] = { zh = "中日韓兼容形式" },
  ["Small Form Variants"] = { zh = "小型變體" },
  ["Arabic Presentation Forms-B"] = { zh = "阿拉伯文表現形式-B" },
  ["Halfwidth and Fullwidth Forms"] = { zh = "半寬與全寬形式" },
  ["Specials"] = { zh = "特殊字符" },
  ["Linear B Syllabary"] = { zh = "線性B音節" },
  ["Linear B Ideograms"] = { zh = "線性B表意文字" },
  ["Aegean Numbers"] = { zh = "愛琴數字" },
  ["Ancient Greek Numbers"] = { zh = "古希臘數字" },
  ["Ancient Symbols"] = { zh = "古代符號" },
  ["Phaistos Disc"] = { zh = "菲斯托斯圓盤" },
  ["Lycian"] = { zh = "呂基亞文" },
  ["Carian"] = { zh = "卡里亞文" },
  ["Coptic Epact Numbers"] = { zh = "科普特曆法數字" },
  ["Old Italic"] = { zh = "古意大利文" },
  ["Gothic"] = { zh = "哥特文" },
  ["Old Permic"] = { zh = "古彼爾姆文" },
  ["Ugaritic"] = { zh = "烏加里特文" },
  ["Old Persian"] = { zh = "古波斯文" },
  ["Deseret"] = { zh = "德瑟雷特文" },
  ["Shavian"] = { zh = "肖維亞文" },
  ["Osmanya"] = { zh = "奧斯曼亞文" },
  ["Osage"] = { zh = "奧塞奇文" },
  ["Elbasan"] = { zh = "埃爾巴桑文" },
  ["Caucasian Albanian"] = { zh = "高加索阿爾巴尼亞文" },
  ["Linear A"] = { zh = "線性A" },
  ["Cypriot Syllabary"] = { zh = "塞浦路斯音節" },
  ["Imperial Aramaic"] = { zh = "帝國阿拉姆文" },
  ["Palmyrene"] = { zh = "帕爾邁拉文" },
  ["Nabataean"] = { zh = "納巴泰文" },
  ["Hatran"] = { zh = "哈特蘭文" },
  ["Phoenician"] = { zh = "腓尼基文" },
  ["Lydian"] = { zh = "呂底亞文" },
  ["Meroitic Hieroglyphs"] = { zh = "梅羅埃象形文字" },
  ["Meroitic Cursive"] = { zh = "梅羅埃草書" },
  ["Kharoshthi"] = { zh = "佉盧文" },
  ["Old South Arabian"] = { zh = "古南阿拉伯文" },
  ["Old North Arabian"] = { zh = "古北阿拉伯文" },
  ["Manichaean"] = { zh = "摩尼文" },
  ["Avestan"] = { zh = "阿維斯塔文" },
  ["Inscriptional Parthian"] = { zh = "帕提亞銘文" },
  ["Inscriptional Pahlavi"] = { zh = "巴列維銘文" },
  ["Psalter Pahlavi"] = { zh = "巴列維聖詩文" },
  ["Old Turkic"] = { zh = "古突厥文" },
  ["Old Hungarian"] = { zh = "古匈牙利文" },
  ["Hanifi Rohingya"] = { zh = "哈尼菲羅興亞文" },
  ["Rumi Numeral Symbols"] = { zh = "盧米數字符號" },
  ["Old Sogdian"] = { zh = "古粟特文" },
  ["Sogdian"] = { zh = "粟特文" },
  ["Elymaic"] = { zh = "埃利邁文" },
  ["Brahmi"] = { zh = "婆羅米文" },
  ["Kaithi"] = { zh = "凱提文" },
  ["Sora Sompeng"] = { zh = "索拉桑彭文" },
  ["Chakma"] = { zh = "查克馬文" },
  ["Mahajani"] = { zh = "馬哈詹尼文" },
  ["Sharada"] = { zh = "沙拉達文" },
  ["Sinhala Archaic Numbers"] = { zh = "僧伽羅古數字" },
  ["Khojki"] = { zh = "科吉文" },
  ["Multani"] = { zh = "穆爾坦文" },
  ["Khudawadi"] = { zh = "庫達瓦迪文" },
  ["Grantha2"] = { zh = "格蘭塔文" },
  ["Newa"] = { zh = "尼瓦文" },
  ["Tirhuta"] = { zh = "蒂爾胡塔文" },
  ["Siddham"] = { zh = "悉曇文" },
  ["Modi"] = { zh = "莫迪文" },
  ["Mongolian Supplement"] = { zh = "蒙古文補充" },
  ["Takri"] = { zh = "塔克里文" },
  ["Ahom"] = { zh = "阿洪文" },
  ["Dogra"] = { zh = "多格拉文" },
  ["Warang Citi"] = { zh = "瓦朗奇蒂文" },
  ["Nandinagari"] = { zh = "南迪納加里文" },
  ["Zanabazar Square"] = { zh = "扎納巴扎方形文字" },
  ["Soyombo"] = { zh = "索永布文" },
  ["Pau Cin Hau"] = { zh = "包欽豪文" },
  ["Bhaiksuki"] = { zh = "拜克蘇基文" },
  ["Marchen"] = { zh = "瑪欽文" },
  ["Masaram Gondi"] = { zh = "馬薩拉姆貢迪文" },
  ["Gunjala Gondi"] = { zh = "貢賈拉貢迪文" },
  ["Makasar"] = { zh = "馬卡薩文" },
  ["Tamil Supplement"] = { zh = "泰米爾文補充" },
  ["Cuneiform"] = { zh = "楔形文字" },
  ["Cuneiform Numbers and Punctuation"] = { zh = "楔形文字數字與標點" },
  ["Early Dynastic Cuneiform"] = { zh = "早期王朝楔形文字" },
  ["Egyptian Hieroglyphs"] = { zh = "埃及象形文字" },
  ["Egyptian Hieroglyph Format Controls"] = { zh = "埃及象形文字格式控制" },
  ["Anatolian Hieroglyphs"] = { zh = "安納托利亞象形文字" },
  ["Bamum Supplement"] = { zh = "巴姆文補充" },
  ["Mro"] = { zh = "姆羅文" },
  ["Bassa Vah"] = { zh = "巴薩瓦文" },
  ["Pahawh Hmong"] = { zh = "帕豪苗文" },
  ["Medefaidrin"] = { zh = "梅德法伊德林文" },
  ["Miao"] = { zh = "苗文" },
  ["Ideographic Symbols and Punctuation"] = { zh = "表意符號與標點" },
  ["Tangut"] = { zh = "西夏文" },
  ["Tangut Components"] = { zh = "西夏文部件" },
  ["Kana Supplement"] = { zh = "假名補充" },
  ["Kana Extended-A"] = { zh = "假名擴展-A" },
  ["Small Kana Extension"] = { zh = "小型假名擴展" },
  ["Nushu"] = { zh = "女書" },
  ["Duployan"] = { zh = "杜普利速記" },
  ["Shorthand Format Controls"] = { zh = "速記格式控制" },
  ["Byzantine Musical Symbols"] = { zh = "拜占庭音樂符號" },
  ["Musical Symbols"] = { zh = "音樂符號" },
  ["Ancient Greek Musical Notation"] = { zh = "古希臘音樂記譜法" },
  ["Mayan Numerals"] = { zh = "瑪雅數字" },
  ["Tai Xuan Jing Symbols"] = { zh = "太玄經符號" },
  ["Counting Rod Numerals"] = { zh = "算籌數字" },
  ["Mathematical Alphanumeric Symbols"] = { zh = "數學字母數字符號" },
  ["Sutton SignWriting"] = { zh = "薩頓手語書寫" },
  ["Glagolitic Supplement"] = { zh = "格拉哥里字母補充" },
  ["Nyiakeng Puachue Hmong"] = { zh = "尼亞肯普阿丘苗文" },
  ["Wancho"] = { zh = "萬喬文" },
  ["Mende Kikakui"] = { zh = "門德基卡庫文" },
  ["Adlam"] = { zh = "阿德拉姆文" },
  ["Indic Siyaq Numbers"] = { zh = "印度錫亞克數字" },
  ["Ottoman Siyaq Numbers"] = { zh = "奧斯曼錫亞克數字" },
  ["Arabic Mathematical Alphabetic Symbols"] = { zh = "阿拉伯數學字母符號" },
  ["Mahjong Tiles"] = { zh = "麻將牌" },
  ["Domino Tiles"] = { zh = "多米諾牌" },
  ["Playing Cards"] = { zh = "撲克牌" },
  ["Enclosed Alphanumeric Supplement"] = { zh = "封閉字母數字補充" },
  ["Enclosed Ideographic Supplement"] = { zh = "封閉表意文字補充" },
  ["Miscellaneous Symbols and Pictographs"] = { zh = "雜項符號與圖形" },
  ["Emoticons"] = { zh = "表情符號" },
  ["Ornamental Dingbats"] = { zh = "裝飾性小圖案" },
  ["Transport and Map Symbols"] = { zh = "交通與地圖符號" },
  ["Alchemical Symbols"] = { zh = "煉金術符號" },
  ["Geometric Shapes Extended"] = { zh = "幾何形狀擴展" },
  ["Supplemental Arrows-C"] = { zh = "補充箭頭-C" },
  ["Supplemental Symbols and Pictographs"] = { zh = "補充符號與圖形" },
  ["Chess Symbols"] = { zh = "國際象棋符號" },
  ["Symbols and Pictographs Extended-A"] = { zh = "符號與圖形擴展-A" },
  ["CJK Unified Ideographs Extension B"] = { zh = "中日韓統一表意文字擴展B" },
  ["CJK Unified Ideographs Extension C"] = { zh = "中日韓統一表意文字擴展C" },
  ["CJK Unified Ideographs Extension D"] = { zh = "中日韓統一表意文字擴展D" },
  ["CJK Unified Ideographs Extension E"] = { zh = "中日韓統一表意文字擴展E" },
  ["CJK Unified Ideographs Extension F"] = { zh = "中日韓統一表意文字擴展F" },
  ["CJK Compatibility Ideographs Supplement"] = { zh = "中日韓兼容表意文字補充" },
  ["Tags"] = { zh = "標籤" },
  ["Variation Selectors Supplement"] = { zh = "變體選擇符補充" },
  ["Supplementary Private Use Area-A"] = { zh = "補充私有使用區-A" },
  ["Supplementary Private Use Area-B"] = { zh = "補充私有使用區-B" },
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
--- @param codepoint integer? Unicode 碼點（十進位或十六進位字符串，例如 0x0251 或 "0251"）
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
