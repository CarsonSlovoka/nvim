# RuntimePath

```lua
:help runtimepath
```

如果你要查`XDG_CONFIG_DIRS`可以用

```
:lua print(vim.fn.stdpath("config"))
```

# PATH 環境變數

windows預設的環境變數可能沒有`HOME`

所以要自己將PATH也添加此路徑，設定成與`vim.fn.stdpath("config")`相同即可

> 注意 .gitconfig 可能也會受到影響，也要將此文件放到`HOME`下

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

# install rust

訪問: https://www.rust-lang.org/tools/install

透過取得安裝檔的方式來安裝

> https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe

```ps1
(gcm cargo).Source
# C:\Users\Carson\.cargo\bin\cargo.exe
cargo -V
# cargo 1.84.1 (66221abde 2024-11-19)
```
