常用的指令

整個help的內容可以參考[keymap.lua](../pack/tree/start/nvim-tree.lua/lua/nvim-tree/keymap.lua)

> https://github.com/nvim-tree/nvim-tree.lua/blob/68fc4c20f5803444277022c681785c5edd11916d/lua/nvim-tree/keymap.lua#L46-L106

| hotkey | desc                                                                                                 |
|--------|------------------------------------------------------------------------------------------------------|
| g?     | 查看幫助
| S      | Search, 不單只是目前看到的項目，包含子目錄的檔案也可以找, 請務必搭配Tab才會有感覺
| a      | Append 可以創建檔案或者目錄
| x      | Cut 剪下檔案, 配合p(貼上)來使用
| r      | Rename 按下去後，它會代入原先的檔名，直接改成你要的即可
| e      | Rename basename. 也可以重新命名，但是只能對basename，不能改變附檔名
| <C-R>  | (R的大小寫沒差) 可以想成是mv，而由於它會代出整個完整路徑(忽略檔案名稱)所以很方便的移動到其它的目錄
| c      | copy 指的是複製文件. 你可以一次c很多個項目, 最後在使用p可以把所有c的項目都貼過去
| p      | paste 例如用了c之後到某一個目錄下按下p可以將此文件複製過去; 如果名稱已經存在，它會直接請你重新命名
| d      | delete 刪除該檔案或目錄會被尋問是否要刪除(即便刪除的是非空目錄，只要確定後都會被刪除)
| q      | Close 可以簡單按下`q`即可，不需要用`:q`等方式來關
| gy     | copy absolute path 複製項目的絕對路徑到剪貼簿 (yank)
| ge     | copy basename
| <C-]>  | CD. tree的路徑看的是最上方目錄名稱
| <C-E>  | Open: In Place 它會直接將檔案開啟到nvim-tree的視窗，然後把nvim-tree關掉
| O      | Open: No Window Picker 如果你有多個窗口，不想要讓其選擇(A, B, ...)，要把它開在主要的視窗，就可以使用此熱鍵
| <C-K>  | ctrl+K 可以查看檔案資訊, `fullpath`, `size`, `accessed`, `modified`, `created`等訊息
| <C-V>  | Open: Vertical Split 如果你有多的視窗，對檔案按下enter後會讓你選擇視窗，但是前提是有多視窗才會有此機制，因些如果想直接產生垂直分頁，可以使用此熱鍵
| <C-X>  | Open: Horizontal Split. 注意如果是同一個檔案就不會有分的效果, 此外如果能分, 它會把選中的放到最近的(因此如果你對於放的位置很在意，還是先分好之後用enter來選擇會比較好)
| <C-T>  | ★ Open: New Tab, `gt`, `gT`可以切換頁籤. `<C-PgUP>`, `<C-PgDown>`也能切換頁籤
| s      | Run System, 用系統的預設指令去執行, 例如你想要看某一個webp的內容時, 如果webp預設是用firefox開啟, 那麼使用此熱鍵它就會幫你用firefox開啟該webp文件 |
| ]c     | Next Git 往下找到有異動的檔案位置
| [c     | Prev Git 往上找到有異動的檔案位置
| H      | Toggle Dotfiles. 可以切換`.`開頭的文件是否要顯示
| I      | Toggle Git Ignore. 可以切換在`.gitignore`清單內的文件是否要顯示
| P      | Parent Directory. 如果你的清單很多，想要快速的回到其目錄的時候即可使用
| W      | Collapse 當你展開很多目錄的時候，此熱鍵可以幫助你縮合所有展開項
| m      | Toggle bookmark. 主要是用於**批次**{移動, 刪除}等用途
| bmv    | Move Bookmarked. 將所有被Toggle的項目(也就是m中的項目)移動過去. 先m之後到指定的目錄用`bmv`. `bmv` 的時候會給確定，如果反悔可以用`<Esc>`(確認是同一性的也就是同意之後所有被選中的都會移動，不會再有各別的確次。
| bt     | **T**rash Bookmarked. 將所有被選中(`m`)的項目 **刪除**
| bd     | **D**elete Bookmarked. 似乎和`bt`一樣
