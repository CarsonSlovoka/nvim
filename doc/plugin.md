# 怎麼寫plugin?

```
github.com/user/my-plugin.nvim
│
├── doc/
│   ├── my-plugin.md  -- 如果txt不善常寫，可以考慮用md轉txt
│   └── my-plugin.txt
│
├── lua/
│   ├── my-plugin/    -- 如果plugin還有要區分一些子功能的時候，可以這樣加，通常的名稱就用成和插件的名稱一樣
│   │    ├── a.lua
│   │    ├── x.lua
│   │    └── n.lua    -- require "my-plugin/n.lua"
│   ├── other.lua     -- require "other.lua" -- 通常不太會這樣
│   └── my-plugin.lua -- require "my-plugin"
│
├── .gitignore
├── .editorconfig
├── ...
├── LICENSE
└── README.md
```

