local kind = {
  search = "search",
  watch = "watch",
  count = "count",
  file = "file",
}

return {
  -- count
  {
    word = 'ls *.webp | grep -c webp',
    abbr = "sh.count",
    kind = kind.count,
    info = 'grep -c 可以用來計數指定的內容'
  },
  -- find
  { word = "find -type f -name README.md  | grep xxx/README.md", kind = kind.search },

  -- -- 這兩個查找(找.git的檔案或目錄)很有用，如果你要找的內容有git版控，那麼透過這兩個指令，一定可以找到檔案路徑
  {
    word = 'find . -type d -name ".git"',
    kind = kind.search,
    info = "列出當前工作目錄下(含子目錄)所有.git的目錄路徑\n如果是submodule請用-type f去找",
  },
  {
    word = 'find . -type d -name ".git" | grep xxx',
    kind = kind.search,
    info = table.concat({
      "列出當前工作目錄下(含子目錄)所有.git的目錄路徑",
      "進一步篩選要有包含xxx的目錄"
    }, ",")
  },
  {
    word = 'find . -type d -name ".git" -exec realpath {} \\; | grep xxx',
    abbr = "findGitD", -- 使用縮寫看到的是縮寫，但是實際上的補全文字還是用word
    kind = kind.search,
    menu = "💡", -- 會列在kind旁邊，可以當成額外的提示
    info = table.concat({
      "列出當前工作目錄下(含子目錄)所有.git的目錄路徑, 轉為絕對路徑",
      "進一步篩選要有包含xxx的目錄"
    }, ",")
  },
  {
    word = 'find . -type f -name ".git"',
    abbr = 'findF',
    kind = kind.search,
    menu = "💡",

    info = "列出當前工作目錄下(含子目錄)所有.git的檔案路徑",
    user_data = {
      example = [[
# 找U2Axxx的文件名
find ~/Downloads/ -type f -name "U2A*"

# 指定附檔名為pdf
find ~/Downloads/ -type f -name "U2A*.pdf"

# 找tag文件
find ~/.config/nvim/ -type f -name "tags"
]]
    }
  },
  {
    word = 'find . -type f -name ".git" | grep xxx',
    kind = kind.search,
    info = "列出當前工作目錄下(含子目錄)所有.git的檔案路徑\n進一步篩選要有包含xxx的檔案"
  },
  {
    word = 'find . -type f -name ".git" -exec realpath {} \\; | grep xxx',
    abbr = "findGitF",
    kind = kind.search,
    menu = "💡",
    info = "列出當前工作目錄下(含子目錄)所有.git的檔案路徑, 轉為絕對路徑\n進一步篩選要有包含xxx的檔案"
  },


  {
    word = 'find . -type d -name "crazy*"',
    abbr = 'findD',
    kind = kind.search,
    menu = "💡",
    info = "於工作目錄中(含子目錄)找所有包含crazy的錄徑",
    user_data = {
      example = [[
find ~/.config/nvim -type d -name "doc"
find ~/.config/nvim -type d -name "cmp*"
find ~/.config/nvim -type d -name "sc*e"
]]
    }
  },
  { word = 'find . -type f ! -name "*.tmp"', kind = kind.search, info = "查找不以 .tmp 结尾的文件" },
  { word = 'find . -mmin -60', kind = kind.search, info = "最近1時小修改的文件" },
  {
    word = 'find ~ -type f -size +10M | head -n 3',
    abbr = 'findFWithSize',
    kind = kind.search,
    info = "列出所有大於10MB的檔案\n" ..
        "head -n 指定筆數，到達了之後就不會再找，如果沒有特別要求要找指定的檔案，這可以加快找的速度"
  },
  {
    word = 'find ~ -type f -size +10M -name "*.pdf" | head -n 3',
    kind = kind.search,
    info = "列出所有大於10MB的pdf檔案\n" ..
        "head -n 指定筆數，到達了之後就不會再找，如果沒有特別要求要找指定的檔案，這可以加快找的速度"
  },

  -- grep
  { word = 'grep -n "myKeyword" README.md', kind = kind.search, info = '找指定檔案內所有的關鍵字\n(-n 會列出它在哪一行)' },
  {
    word = 'grep -r "vhea" ~/Downloads/',
    kind = kind.search,
    info = '找~/Downloads內所有，有vhea的項目'
  },
  {
    word = 'grep -rn --include="*.md" --include="*.sh" "SearchContent" ~',
    kind = kind.search,
    abbr = 'grepW', -- Words
    menu = "💡",
    info = [[
找關鍵字的內容，在哪一個檔案的第幾列

可以透過`--include`來指定要搜尋的附檔名
有多個附檔名可能用多個`--include`來指定
]],
    user_data = {
      example = [[
# 找可能是透過fontforge所產生的字型檔(它有FFTM表)
grep -rn --include="*.ttf" --include="*.otf" "FFTM" ~/Downloads/

# 可以再透過再接一次grep來篩選
grep -rn --include="*.sh" "install" ~ | grep install.sh

# 同上，但是再取前三筆就好(會找的更快)
grep -rn --include="*.sh" "install" ~ | grep install.sh | head -n 3
]]
    }
  },
  { word = 'grep -lr --include="*.sh" "install"', kind = kind.search, info = '找所有sh附檔名的檔案且有包含install關鍵字\n(-l 只會顯示檔案路徑)' },
  {
    word = 'grep -r --include="*.otf" --include="*.ttf" "name" ~/Downloads/',
    kind = kind.search,
    info = '找~/Downloads內所有附檔名為{otf, ttf}，有name的項目\n二進位也可以搜'
  },
  {
    word = 'grep -r -C 3 --exclude="*.txt" setup ~/.config/nvim/',
    kind = kind.search,
    info = '於指定目錄(含子目錄)查找有setup的檔案，列出關鍵字行的前後3列'
  },
  {
    word = 'grep -E "## grep .*文" -C 3 my.md',
    kind = kind.search,
    info = '於my.md查找\n-E表示啟用正規式'
  },
  {
    word = 'grep -n "target" file1 file2 file3',
    kind = kind.search,
    info = '於file1, file2, file3中查找有target的列資料\n-n會顯示列號'
  },
  {
    word = 'grep -n "^start" file',
    kind = kind.search,
    info = '批配開頭為start的內容\n(^ 不需要使用-E, 預設就會有)'
  },
  {
    word = 'grep -n "end$" file',
    kind = kind.search,
    info = '批配結尾為end的內容\n($ 不需要使用-E, 預設就會有)'
  },


  -- ldd
  { word = 'ldd /bin/bash', kind = kind.watch, info = '查找該可執行文件，其用到的相關動態連結庫(so, dll, shardlib)' },

  { word = 'ldd /bin/bash | grep -c ".so"', kind = kind.count, info = '計算用到的so數量' },


  {
    word = 'split -n 3 -d "my.pdf" my_part_',
    kind = kind.file,
    info = "將my.pdf分割為三個檔案，每一個檔案用my_part_當成全綴\n" ..
        "-n表示要拆成的數量\n" ..
        "-d 使用數字當成拆分的流水號，而非使用字母，如果沒有預設用字母來當成流水號(aa, ab, ac ...)"
  },
  {
    word = 'cat my_part_* > my.pdf',
    kind = kind.file,
    info = "將所有my_part_的內容合併成一個，變成my.pdf"
  },
  {
    word = 'cat my_part_00 my_part_01 > my.pdf',
    kind = kind.file,
    info = "將my_part_00與my_part_01的內容合在一起成為my.pdf檔案"
  },
}
