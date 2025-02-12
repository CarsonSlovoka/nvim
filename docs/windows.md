# RuntimePath

```lua
:help runtimepath
```

如果你要查`XDG_CONFIG_DIRS`可以用

```
:lua print(vim.fn.stdpath("config"))
```

它所謂的`$XDG_CONFIG_DIRS`或者`XDG_CONFIG_HOME`都是指環境變數，例如你可以改成

```bash
setx XDG_CONFIG_HOME %userprofile%\.config # 加在使用者個人環境變數
setx XDG_CONFIG_HOME %userprofile%\.config /M # 加在系統環境變數
```

如果沒特別的需求建議就用預設的不需要修改

# PATH 環境變數

windows預設的環境變數可能沒有`HOME`

所以要自己將PATH也添加此路徑，設定成與`vim.fn.stdpath("config")`相同即可

```shell
setx HOME %userprofile%\AppData\Local
```

> 注意 .gitconfig 可能也會受到影響，也要將此文件放到`HOME`

```shell
# 從 %userprofile%\.gitconfig 搬移至 %userprofile%\AppData\Local\.gitconfig
# (不建議留兩個，可能會遇到gitk卡頓的問題(雖然我最後更新git之後就沒再遇到了，但是此時的.gitconfig我指留一份))
```


# Fonts

## 更換終端機字體

首先你要有合適的字體

> https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip
>
> (版本可以[找](https://github.com/ryanoasis/nerd-fonts/releases/)比較新的)
>
> 下載完安裝該字體即可, 建議用: `FiraCodeNerdFontMono-Retina.ttf`

另外你的終端機也必須要有支持該字體(否則會不到該字體), 才可以顯示

建議可以用wt, 目前windows 11預設就已經用wt

> https://learn.microsoft.com/zh-tw/windows/terminal/install

如果是win10可以從商店來下載並安裝

> https://aka.ms/terminal

之後可以

```
設定  > 外觀 > 文字 > 字體
                  > 字體大小
                  > (如果是可變字體，這邊也還能再調整)
```

![how-to-change font-family](https://private-user-images.githubusercontent.com/17170765/410737041-fe2be486-2349-4da8-89c0-6d1c0466304c.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3Mzg4OTY5NzYsIm5iZiI6MTczODg5NjY3NiwicGF0aCI6Ii8xNzE3MDc2NS80MTA3MzcwNDEtZmUyYmU0ODYtMjM0OS00ZGE4LTg5YzAtNmQxYzA0NjYzMDRjLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAyMDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMjA3VDAyNTExNlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWVlMDYwODhjNDNhNTE2M2IxZTI3YTlmYTk1NmY0NTQxZGU1NzdmM2FlMTBkMGFiMGQ3MTRhYzNjNzRlNjI1ODgmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.OnxRViADvMrGgAKmJSCmEXv5RMr_L0HGPPPJeDUb_-8)

# Install

## install rust

訪問: https://www.rust-lang.org/tools/install

透過取得安裝檔的方式來安裝

> https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe

```ps1
(gcm cargo).Source
# C:\Users\Carson\.cargo\bin\cargo.exe
cargo -V
# cargo 1.84.1 (66221abde 2024-11-19)
```

## install lua-language-server

如果沒有安裝你可能會遇到以下這些訊息

```
nvim-win64\share\nvim\runtime/lua/vim/lsp/_transport.lua:68: Spawning language server with cmd: `{ "lua-language-server" }` failed.

The language server is either not installed, missing from PATH, or not executable.
```

> 🧙 請記得不管是哪一種安裝方法，安裝好了要把終端機(是終端機)關掉再重啟才會生效，如果你單純只有把nvim退出在啟用，這樣它的PATH還是不會被更新

### source安裝 (建議用這個比較簡單)

https://github.com/LuaLS/lua-language-server/releases

https://github.com/LuaLS/lua-language-server/releases/download/3.13.6/lua-language-server-3.13.6-win32-x64.zip

透過以上方式弄完之後，要在PATH新增環境變數: `C:\usr\bin\lua-language-server\bin` (實際的位置依據你解壓出來後所放到的目錄為準)

完成之後請關閉終端機後再打開！

### 用scoop安裝

從[lspconfig/configs/lua_ls.lua](https://github.com/neovim/nvim-lspconfig/blob/75edb91a3d2deabe76a9911cde2c13d411b3b097/lua/lspconfig/configs/lua_ls.lua#L82-L84)會有以下提示

```
See `lua-language-server`'s [documentation](https://luals.github.io/wiki/settings/) for an explanation of the above fields:
* [Lua.runtime.path](https://luals.github.io/wiki/settings/#runtimepath)
* [Lua.workspace.library](https://luals.github.io/wiki/settings/#workspacelibrary)
```

再去細看就會發現可以透過`scoop`套件管理工具來安裝

> 安裝[scoop](https://scoop.sh/)

使用powershell5 (注意**不**要用管理員身分執行，會報錯)

```ps1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

完成後就取得到scoop的工具了

---

另外由[neovim-install](https://luals.github.io/#neovim-install)得知, 以下這三種套件管理工具都可以安裝lua-language-server

- Scoop: `scoop install lua-language-server`
- Homebrew: `brew install lua-language-server`
- Macports: `sudo port install lua-language-server`

以下為scoop

```ps1
scoop install lua-language-server
# 'lua-language-server' (3.13.6) was installed successfully!

# 解除安裝 (如果要解除安裝nvim要先關掉)
scoop uninstall lua-language-server
```

記得關閉終端機後再打開才會生效(讓`PATH`被更新)

### install lua

https://github.com/rjpcomputing/luaforwindows/releases

https://github.com/rjpcomputing/luaforwindows/releases/download/v5.1.5-52/LuaForWindows_v5.1.5-52.exe

安裝完成之後首次會有一些lua的範例

或者你也可以在這邊找[lua/examples](https://github.com/rjpcomputing/luaforwindows/tree/master/files/examples)

## install pyenv

目前[pyenv並不支持純windows](https://github.com/pyenv/pyenv/blob/d327702c4de949136e1d351bf3027513de90d1e9/README.md?plain=1#L163-L170)

它的建議是可以找另一個分支

> https://github.com/pyenv-win/pyenv-win

使用powershell, 並且用管理員身分執行以下命令

```bash
# 安裝
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
# 完成後建議重新啟動終端機


# 查看
pyenv --version
# pyenv 3.1.1

# 安裝
pyenv install -l # 查看有哪些版本可以安裝
pyenv intsll <version> # 找一個你想要安裝的版本
pyenv versions # 查看當前你有裝了那些版本的python
pyenv global <version> # 全局的解析器用此版本來套用

# 安裝範例
pyenv versions # 如果沒有裝在準備安裝
pyenv install 3.13.1
pyenv global 3.13.1
pyenv versions # 看看是否真的有被套用(前面會加上 `*` )
```

確定以下兩個路徑真的有被加到`PATH`使用者環境變數 (安裝的腳本其實已經有做這個動作)
```
%userprofile%\.pyenv\pyenv-win\bin
%userprofile%\.pyenv\pyenv-win\shims
```


# FAQ

## gitk --all卡頓

你會發現如果新增了`HOME`環境變數，使用`gitk --all`去查看時，可能就會卡住都沒有回應

它與你環境變數設定在哪, 調整`GIT_CONFIG_GLOBAL`這些環境變數都無關，弄了還是可能會再遇到問題

有可能是你的git版本太舊，直接重新下載git或者用`git update-git-for-windows`去升級後即可

先查看git的版本

```bash
git --version
# git version 2.33.1.windows.1

# 升級git
git update-git-for-windows
git --version
git version 2.47.1.windows.2
```

## [E138: main.shada.tmp.X files exist, cannot write ShaDa](https://github.com/neovim/neovim/issues/8587)

[issues-11955](https://github.com/neovim/neovim/issues/11955)

```shell
cd ~\AppData\Local\nvim-data\shada
ls # 查看檔案，應該會看到很多的tmp.xx的檔案
rm main.shada.tmp.* # 將這些檔案都移除之後，錯誤應該就不會再有
```
