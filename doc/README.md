# 生成文檔幫助

```yaml
# :helptags ~/path/to/your/plugin/doc
:helptags ~/.config/nvim/doc
# 完成之後會於指定的目錄，生成出一個tags的檔案
```

除非有新文件，不然你面的內容，在你每次nvim的時候，都會即時去抓

也就是只要有更新，你要將nvim重新開啟即可看到更新後的內容

> 注意，如果tag文件被刪除，當下不用重啟就已經無法再查看到幫助

# 格式

```
*tag*         - 標籤定義
|link|        - 鏈接到其他幫助主題, 透過 K (大小，可以全往該tag)
>command<     - 命令(or codeblock)
`example`     - 代碼示例
```

多行的 command 前面一定要有4個空白
```yaml
>    
    ls -l
<
```

錯誤，沒有空白
```yaml
>    
ls -l
<    
```

錯誤，不能寫一列
```
>ls -l *.png<    
```

# highlight

如果發現沒有顏色的突顯，可能是filetype不正確的關係，請用`:set ft`去設定

```yaml
# 查看filetype
:set ft?

# 強制將filetype改為help
:set ft=help
```