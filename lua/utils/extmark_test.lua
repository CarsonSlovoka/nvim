local m = require("utils.extmark")
m.set_conceal(
  "id_test1",
  {
    patterns = { "party", "ya" },
    conceal = "🎉"
  }
)

m.set_conceal_with_replacements(
  "id_test2",
  {
    replacements = {
      { patterns = { "hello", "hi" }, conceal = "👋" },
      { patterns = { "world" }, conceal = "🌍" },
      { patterns = { "lua" }, conceal = "🔧" }
    }
  }
)

m.set_conceal_with_replacements(
  "id_test_http",
  {
    replacements = {
      {
        patterns = {
          "https?://[%w%.%-]+%.[%a][%a%d]+[/:%w%.%-_~?&#=]*",
        },
        conceal = "🌎"
      }
    }
  }
)
