# mkspell

```lua
-- :mkspell <outLang> <in>
:mkspell zh zh.wordlist -- zh.wordlist應該工作目錄中
:mkspell ~/.config/nvim/spell/zh ~/.config/nvim/spell/zh.wordlist -- 或者也可以用絕對路徑
-- :mkspell ~/.config/nvim/spell/cn/cn ~/.config/nvim/spell/cn/cn.wordlist ❌ 似乎只能在spell這層目錄下(不含子目錄)
```

完成之後mkspell會依據輸入的檔案`zh.wordlist`來生成出`<outLang>.utf-8.spl`的檔案, 例如: `zh.utf-8.spl`

而如果之後用`zg`, 則會在runtimepath最先抓到的路徑下的`spell`目錄中對應的兩個文件做調整(如果不存在就會新增)

1. `<outLang>.utf-8.add`  明碼，可以看到加入的單詞
2. `<outLang>.utf-8.add.spl` 二進位資料


# 在自義定專案中加入spell

```
~/myProject/spell/qoo.wordlist
```

接著調整runtimepath, 否則`set spelllang`還是會抓不到

```lua
-- :lua vim.opt.runtimepath:append(vim.fn.expand("~/myProject/")) -- 不建議這樣，這是加到最後面，如此用 zg 增字的時候，相關的檔案路徑產生的地方可能不如預期
:set runtimepath=~/myProject/,$VIMRUNTIME
:set runtimepath
:set runtimepath -- 查看
:mkspell ~/myProject/spell/qoo ~/myProject/spell/qoo.wordlist
set spell spelllang=qoo
-- set spell spelllang=zh,en -- 💡 spelllang 也可以設定多個
```

