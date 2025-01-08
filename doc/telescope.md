```
:Telescope <command>
```

# git

## git_commits

```yaml
:Telescope git_commits
# 與gitk很像可以看到每個commit異動了哪些檔案，只是它所有的檔案異動都寫一起，不能用選擇檔案去看, 要慢慢page down找到該檔案
```

## git_status

```yaml
:Telescope git_status
# 查看本次異動的情況，就下用gitk查看當前所有的修改一樣
```

## git_bcommits

blame commits用該檔案去查看所其所有的歷史異動

```yaml
:Telescope git_bcommits
```

## git_bcommits_range

類似bcommits只是它檢視的異動只會以當前光標的所在列為主

歷史異動有與該列有關才會出來

```
:Telescope git_bcommits_range
```

## ~~git_branches~~

沒什麼用，只是顯示所有分支

```
:Telescope git_branches
```

## git_files

可以用來找檔案，如果你確定要找的檔案已經有commit了

那可以用這種方式來找尋

```
:Telescope git_files
```

# buffers

## ★ buffers

```
:Telescope buffers
# 為 :buffers 的加強版，只是能提供篩選和preview

ESC
? # 可以開啟幫助
<M-d> <-> Alt-d -> delete_buffer
<Tab> -> toggle  可以先選取後再使用<M-d>來批量刪除
# 當有啟動sort_mru時就不需要管排序，讓其自己安排，有需要用到的只有刪除不需要的buffer
```

# help

## help_tags

help文檔的所有tag的會出現，如果要找查找doc相關的幫助可能有用

```
:Telescope help_tags
```

## man_pages

如果要使用 `man xxx` 的時候可以考慮用它

```
:Telescope man_pages
```

# others

## keymaps

與`maps`類似只是更好看,而且還可以篩選, 此時keymaps上的幫助就會很清楚

選取確認之後可以執行

```yaml
:Telescope keymaps
:maps
```

> 注意，不同的文件其keymaps的內容可能會有不同，因為有些keymap是特定文件或者模式下才會有的

- gc: toggle comment (n, x模式都行)
- gx: opens filepath or URI under cursor with the system handler(file explorer, web browser, ...)

## commands

```yaml
:Telescope commands
# 為 :command 的加強，列出所有定義的command
```

## ★ current_buffer_fuzzy_find

```yaml
:Telescope current_buffer_fuzzy_find
# 簡單來說就是對目前的文件進行搜尋，好處是可以直接看到當前文件所有的匹配項目
```

## highlights

可以挑選顏色，主要是用於[開發plugin時](https://github.com/CarsonSlovoka/nvim/blob/c2a10266940dff5f3d429a7f26adf65718e71c6f/lua/config/telescope_bookmark.lua#L256-L267)，想要突顯顏色再考慮用哪一個的時候會用到

```yaml
:Telescope highlights
# 類似 :highlight
```

## ~~colorscheme~~

沒什麼用，只是換主題顏色

```yaml
:Telescope colorscheme
```

## ~~filetype~~

可以找所有支援的檔案類型

```yaml
:Telescope filetype
```

## jumplist

類同`:jumps`

```
:Telescope jumplist
```

## marks

類似marks

```
:Telescope marks
```

## registers

類同`:reg`

```
:Telescope registers
```

## ~~planets~~

趣味用，TUI八大行星

```
:Telescope planets
```

## search_history

曾經`/`, `?`, `#`, `*`過的歷史

```
:Telescope search_history
```

## vim_options

查看vim的設定

```
:Telescope vim_options
```

