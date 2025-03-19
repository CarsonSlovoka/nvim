local m = require("utils.extmark")
m.set_conceal(
  {
    id = "my_foo",
    patterns = { "party", "ya" },
    conceal = "🎉"
  }
)

m.set_conceal_with_replacements(
  {
    id = "my_conceal",
    replacements = {
      { patterns = { "hello", "hi" }, conceal = "👋" },
      { patterns = { "world" }, conceal = "🌍" },
      { patterns = { "lua" }, conceal = "🔧" }
    }
  }
)
