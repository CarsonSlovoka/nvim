local kind = {}
kind.search = "search"

return {
  -- find
  { word = "find -type f -name README.md  | grep xxx/README.md", kind = kind.search },

  { word = 'find . -type d -name ""', kind = kind.search },
  { word = 'find . -type f ! -name "*.tmp"', kind = kind.search, info = "查找不以 .tmp 结尾的文件" },
  { word = 'find . -mmin -60', kind = kind.search, info = "最近1時小修改的文件" },
}
