local utils = require("utils.utils")

-- require("dap").adapters.custome = {
--   type = 'executable',
--   command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
-- }

-- -@type vim.SystemCompleted r

---@param exe_name string
---@param param table
---@param ok_lines table 成功後的前導輸出文字
---@param opts table
local function show_run_result(exe_name, param, ok_lines, opts)
  if vim.fn.executable(exe_name) == 0 then
    return
  end
  local r = vim.system({ exe_name, unpack(param) }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ [%s] err code: %d err msg: %s", exe_name, r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  -- local text = {
  --   "file: " .. fontpath,
  --   "result: ",
  --   " ",
  --   unpack(vim.split(r.stdout, "\n"))
  -- }
  local lines = ok_lines
  for _, line in ipairs({
    '',
    string.format("cmd: %s %s", exe_name, table.concat(param, " ")),
    '',
  }) do
    table.insert(lines, line)
  end

  table.insert(lines, "stdout:")
  for _, line in ipairs(vim.split(r.stdout, "\n")) do
    table.insert(lines, line)
  end

  table.insert(lines, "stderr:") -- 有些訊息也會寫在這邊，所以也有納入
  for _, line in ipairs(vim.split(r.stderr, "\n")) do
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for _, cmd in ipairs(opts.cmds) do
    -- vim.cmd([[call matchadd('@label', '\v^\w*:')]]) -- 預設的作用域是當前的window, 不過可以透過 :call clearmatches() 來全部清除
    -- vim.cmd([[call matchadd('@label', '\v\w*:', 10, -1, {'window': 1013})]]) -- 可以透過這種方式指定成其它的window
    vim.cmd(cmd)
  end
  vim.cmd(string.format([[call matchadd('MiniIconsOrange', '%s')]], exe_name))
  vim.cmd("file " .. exe_name) -- 設定為有意義的名稱，不要使用No Name
end

local function program_otparser()
  -- 確保執行檔存在
  -- otparser.exe: https://github.com/CarsonSlovoka/otparser.nvim/blob/28c84b9320725582290a56d7c4af06c998d5495a/main.go#L59-L79
  if vim.fn.executable("otparser") == 0 then
    return
  end

  local fontPath = vim.fn.expand("%:p")
  local fontname = "♻️" .. vim.fn.expand("%:t") -- 為了盡量避免與當前的buf同名，前面加上♻️ (如果要完全避免誤判，要額外記錄buffer id)
  -- :echo expand("%:t") -- xxx.lua
  -- :echo expand("%:e") -- lua

  local exists, buf = utils.api.get_buf(vim.fn.getcwd() .. "/" .. fontname)
  if not exists then
    -- vim.api.nvim_command("vsplit enew")
    vim.api.nvim_command("enew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- 設定為nofile就已經是不能編輯，但這只是代表可以編輯但是無法保存當前的檔案，但是可以用:w ~/other.txt 的方式來另儲
    -- vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf }) -- 不在buffer中記錄

    -- vim.api.nvim_buf_set_name(buf, bufName) -- 注意！要給檔名就好
    vim.api.nvim_buf_set_name(buf, fontname) -- 如果name是No Name時，使用vimgrep會遇到錯誤: E499: Empty file name for '%' or '#', only works with ":p:h" 因此為了能使vimgrep還是能有一個檔案的參照，需要設定其名稱
    -- note: 使用nofile時再使用nvim_buf_set_name仍然有效，它會限制此檔案不能被保存
    -- note: nvim_buf_set_name 的文件名稱，是在當前的工作目錄下建立此名稱
    -- note: 如果buffer已經存在，會得到錯誤: Vim:E95: Buffer with this name already exists

    vim.bo.filetype = "opentype"
  elseif buf then
    vim.api.nvim_set_current_buf(buf)
  end

  -- local output = vim.fn.system("otparser " .. vim.fn.shellescape(curFile)) -- 也行，但是建議用vim.system更明確
  --- @type table
  local r = vim.system({ "otparser", fontPath }):wait()
  if r.code ~= 0 then -- 用回傳的code來當是否有錯的基準
    vim.notify(string.format("❌ otparser error. err code: %d %s", r.code, r.stderr), vim.log.levels.WARN)
    return
  end

  if buf then
    -- -- vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(r.stdout, "\n")) -- 是可以直接寫在原本的地方，但是如果對原始的二進位有興趣，直接取代就不太好，所以另外開一個buffer寫
    -- -- vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))

    -- vim.api.nvim_set_option_value("modifiable", false, { buf = buf }) -- readonly, 會直接連Insert都無法使用. 記得要放在nvim_buf_set_lines之後
  end

  if vim.fn.executable("xxd") == 0 then
    return
  end

  -- 再建立一個新的buf來放xxd的結果
  -- vim.cmd("vnew")
  vim.cmd("vnew ++bin") -- 要補上++bin才可以讓%!xxd -r時得到原始的內容
  vim.cmd("wincmd L")   -- 放到最右邊

  -- { text = "head | 436 | 54" },
  -- lua print(string.format("%x", 436)) -- 起始從00開始
  -- lua print(string.format("%x", 436+54-1)) -- 不包含最後一個
  buf = vim.api.nvim_get_current_buf()
  local helps = {
    'Tag  | Offset | Length',
    'head | 436    | 54',
    '436+',
    'V53+',
    '',
    -- 可行，但是start, end輸入會被影響
    -- 'let start = printf("%08x", 436)',
    -- 'let end = printf("%08x", 436+53)',
    -- "let cmd = printf('/%s/,/%s/yank', start, end)",
    'let start = 436',
    'let end = 436+53',
    "let cmd = printf('/%s/,/%s/yank', printf('%08x', start), printf('%08x', end))",
    ':execute cmd',
    ':tabnew ++bin',
    ':pu=@"',
    '',
    '',
    ':lua print(string.format("%x", 436))',
    ':lua print(string.format("%x", 436+53))',
    ':/1b4/,/1e9/yank',
    '',
    '',
    [[:call matchadd("Yellow", '\v^\d+.*')]], -- 需要\v才可以用^ -- ⚠️ 在vim上用單引號，雙引號會不行
    [[:let m = matchadd("Blue", '\v^\d+')]],
    ':call matchdelete(m)',
    '',
    '',
    "'<,'>Highlight YellowBold *",
    ":copen 5",
    "%!xxd -r",
    "54GoSelect 437",
    ' ', -- 這個用來放xxd的內容
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, helps)
  local ns_id = vim.api.nvim_create_namespace("hightlight_comment")
  vim.hl.range(buf, ns_id, "Comment", { 0, 0 }, { #helps, -1 }) -- ns_id不可以用0，一定要建立
  vim.cmd("normal! G")

  -- vim.cmd("r !xxd -c 1 " .. fontPath) -- 這個會有:mes的訊息，如果不想要，可以用vim.fn.systemlist來代替
  local output = vim.fn.systemlist("xxd -c 1 " .. fontPath)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, output)

  -- vim.fn.setloclist(0, {
  vim.fn.setqflist({ -- 這有可能在其它的buffer也需要參考，所以用qflist會比較好點
    { text = "vnew ++bin" },
    { text = "r !xxd -c 1 " .. fontPath },
    { text = "r !xxd -c 16 " .. fontPath },
    { text = "%!xxd -r" },
  }, 'a')

  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
end

local function program_convert2ttx()
  if vim.fn.executable("python") == 0 then
    return
  end

  local fontpath = vim.fn.expand("%:p") -- 獲取當前檔案的完整路徑

  -- 因為已經是確定filetype是自定的opentype所以就不做附檔名的判斷了
  -- local ext = vim.fn.expand("%:e"):lower() -- 獲取副檔名（小寫）
  -- -- 檢查是否為 ttf 或 otf 檔案
  -- if ext ~= "ttf" and ext ~= "otf" then
  --   return
  -- end

  local python_code = string.format([[
import io
import sys

from fontTools.misc.xmlWriter import XMLWriter
from fontTools.ttLib import TTFont

font = TTFont("%s")

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
writer = XMLWriter(sys.stdout, newlinestr="\n")
font._saveXML(writer)
]], fontpath)

  local r = vim.system({ "python3", "-c", python_code }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ fontTools.TTFont.saveXML error. err code: %d %s", r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("filetype", "ttx", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
  return ""
end

local SCRIPT_SHOW_GLYPH = [[
import base64
import csv
import io
import sys
from typing import Any

import freetype  # pip install freetype-py==2.5.1
from fontTools.ttLib import TTFont  # pip install fonttools==4.59.2
from fontTools.ttLib.tables._c_m_a_p import table__c_m_a_p
from fontTools.ttLib.tables._m_a_x_p import table__m_a_x_p
from PIL import Image

font_path = "%s"
font: Any = TTFont(font_path)

class GlyphRenderer:
    """用於將字型檔案的 glyph 渲染為 Kitty 終端機圖形控制序列的類"""

    def __init__(self, font_path, **kwargs):
        """初始化字型檔案並創建 FreeType Face 物件"""
        try:
            self.face = freetype.Face(font_path)
            self.face.set_char_size(kwargs.get("width", 48) * kwargs.get("height", 48))
        except Exception as e:
            raise ValueError(f"Failed to initialize font at {font_path}: {str(e)}")

    def render_glyph_to_kitty(self, glyph_index) -> str:
        """將指定 glyph index 渲染為 Kitty 終端機圖形控制序列"""
        try:
            self.face.load_glyph(glyph_index, getattr(freetype, "FT_LOAD_RENDER"))
            bitmap = self.face.glyph.bitmap
            width, rows = bitmap.width, bitmap.rows
            if width == 0 or rows == 0:
                return ""  # glyph無效

            data = bytes(bitmap.buffer)
            img = Image.frombytes("L", (width, rows), data)  # gray mode

            # 轉成 PNG bytes
            buf = io.BytesIO()
            img.save(buf, format="PNG")
            png_data = buf.getvalue()

            b64 = base64.b64encode(png_data).decode("ascii")

            chunk_size = 4096
            output = []
            for i in range(0, len(b64), chunk_size):
                chunk = b64[i : i + chunk_size]
                m = 1 if i + chunk_size < len(b64) else 0
                output.append(f"\033_Gf=100,a=T,m={m};{chunk}\033\\")
            return "".join(output)
        except Exception as e:
            return f"Error rendering glyph {glyph_index}: {str(e)}"

def expand_ranges_to_array(ranges):
    """
    將範圍列表展開為單一陣列
    :param ranges: 範圍列表，如 [["100", "200"], ["50", "88"], ...]
    :return: 包含所有範圍內整數的集合（去重複）
    """
    if len(ranges) == 0:
        return set()
    result = set()
    try:
        for start, end in ranges:
            start_num = int(start)
            end_num = int(end)
            result.update(range(start_num, end_num + 1))  # 包含 end
    except (ValueError, TypeError):
        print("錯誤：範圍列表格式不正確或包含無效數字")
    return result


def main(show_outline: bool, glyph_index=[]):
    target_glyph_index_set = expand_ranges_to_array(glyph_index)

    cmap: table__c_m_a_p = font["cmap"]
    maxp: table__m_a_x_p = font["maxp"]

    glyph_order = font.getGlyphOrder()

    header = [
        "gid",
        "glyphName",
        "isUnicode",
        "unicode codepoint",
        "unicode ch",
        "outline",
    ]

    writer = csv.DictWriter(sys.stdout, fieldnames=header, lineterminator="\n")
    writer.writeheader()

    best_unicode_cmap_subtable = (
        cmap.getBestCmap()
    )  # TIP: 這個的範圍都是找unicode的cmap

    glyphname_to_unicode_map = {}
    if best_unicode_cmap_subtable is not None:
        glyphname_to_unicode_map = {
            glyph_name: codepoint
            for codepoint, glyph_name in best_unicode_cmap_subtable.items()
        }

    glyph_render = GlyphRenderer(font_path, width=96, height=48)
    for gid, glyph_name in enumerate(glyph_order):
        # if gid != 22231: continue

        if len(target_glyph_index_set) > 0 and gid not in target_glyph_index_set:
            continue
        row = {
            "gid": gid,
            "glyphName": glyph_name,
            "isUnicode": False,  # 後面再修正
        }
        if best_unicode_cmap_subtable is not None:
            if (
                unicode_point := glyphname_to_unicode_map.get(glyph_name, None)
            ) is not None:
                row["isUnicode"] = True
                row["unicode codepoint"] = f"U+{unicode_point:04x}"
                row["unicode ch"] = chr(unicode_point)

        if show_outline:
            row["outline"] = glyph_render.render_glyph_to_kitty(gid) # nvim 沒辦法做，再外層的終端機可以

        writer.writerow(row)

main(%s, %s)
]]

local function program_show_glyph()
  if vim.fn.executable("python") == 0 then
    return
  end

  local fontpath = vim.fn.expand("%:p")

  local python_code = string.format(
    SCRIPT_SHOW_GLYPH,
    fontpath,
    "False", -- show_outline: False
    "[]"
  )

  local r = vim.system({ "python3", "-c", python_code }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ program_show_glyph err code: %d %s", r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end
  vim.cmd("tabnew | setlocal buftype=nofile")
  vim.cmd("file glyph: " .. vim.fn.expand("%:r"))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("filetype", "csv", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))

  return ""
end



local function program_show_glyph_with_kitty()
  if vim.fn.executable("python") == 0 then
    return
  end

  local input = vim.fn.input("glyph_index (ex: 1..200 500..600)") -- 一開始給一個空白，避免str.split分離錯
  local ranges = {}
  local groups = vim.split(input or "", " ")
  for _, g in ipairs(groups) do
    local start, finish = g:match("(%d+)%.%.(%d+)") -- 不要取start, end (end是保留字)
    if start and finish then
      table.insert(ranges, { start, finish })
    end
  end
  local json_str_glyph_index = vim.fn.json_encode(ranges)

  local fontpath = vim.fn.expand("%:p")
  local file, err = io.open("/tmp/show_glyph", "w")
  if not file then
    vim.notify("無法打開檔案 " .. err, vim.log.levels.WARN)
    return
  end
  file:write(string.format(SCRIPT_SHOW_GLYPH, fontpath, "True", json_str_glyph_index))
  file:close()

  vim.cmd("tabnew | setlocal buftype=nofile | term")
  vim.cmd("startinsert")
  vim.api.nvim_input([[kitty --hold python /tmp/show_glyph <CR>]]) -- hold可以讓終端機保持，不會執行完腳本後就關閉
  vim.fn.setqflist({
    { text = ":r! python /tmp/show_glyph                       📝 可以得到輸出的結果", },
    { text = ":r! python /tmp/show_glyph > /tmp/show_glyph.csv 📝 另儲新檔", },
    { text = ":!kitty --hold cat /tmp/show_glyph.csv &         📝 接著在kitty使用cat也可以看到圖片", },
  }, 'a')
end

local function program_font_validator()
  if vim.fn.executable("font-validator") == 0 then
    vim.notify(
      "font-validator not found.\n" ..
      "wget https://github.com/HinTak/Font-Validator/releases/download/FontVal-2.1.6/FontVal-2.1.6-ubuntu-18.04-x64.tgz\n" ..
      "tar -xvzf FontVal-2.1.6-ubuntu-18.04-x64.tgz\n" ..
      'sudo ln -siv "$HOME/FontVal-2.1.6-ubuntu-18.04-x64/FontValidator-ubuntu-18.04-x64" /usr/bin/font-validator'
      ,
      vim.log.levels.WARN
    )
    return
  end

  local fontPath = vim.fn.expand("%:p")
  local fontname = "♻️" .. vim.fn.expand("%:t")
  local exists, buf = utils.api.get_buf(vim.fn.getcwd() .. "/" .. fontname)
  if not exists then
    vim.api.nvim_command("enew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_buf_set_name(buf, fontname)
    -- vim.bo.filetype = "opentype"
  elseif buf then
    vim.api.nvim_set_current_buf(buf)
  end

  local r = vim.system({ "font-validator", "-file", fontPath, "-stdout" }):wait()
  -- if r.code ~= 0 then -- 它回的可能都不會是0, 所以乾脆不判斷
  --   vim.notify(string.format("❌ font-validator error. err code: %d %s", r.code, r.stderr), vim.log.levels.WARN)
  --   return
  -- end

  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
  end
end

local function program_ots_sanitize()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-sanitize", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
  return ""
end

local function program_ots_idempotent()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-idempotent", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_validator()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-validator-checker", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_side_by_side()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-side-by-side", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_perf()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-perf", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_batch_run()
  local org_tab = vim.api.nvim_get_current_tabpage()
  program_ots_sanitize()
  vim.api.nvim_set_current_tabpage(org_tab)
  program_ots_idempotent()
  vim.api.nvim_set_current_tabpage(org_tab)
  program_ots_validator()
  vim.api.nvim_set_current_tabpage(org_tab)
end

require("dap").configurations.opentype = {
  {
    name = "otparser",
    type = "custom",
    request = "launch",
    program = program_otparser,
  },
  {
    name = "convert to fontTools:ttx format",
    type = "custom",
    request = "launch",
    program = program_convert2ttx,
  },
  {
    name = "show glyph",
    type = "custom",
    request = "launch",
    program = program_show_glyph,
  },
  {
    name = "show glyph (with kitty)",
    type = "custom",
    request = "launch",
    program = program_show_glyph_with_kitty,
  },
  {
    name = "font-validator",
    type = "custom",
    request = "launch",
    program = program_font_validator,
  },
  {
    name = "ots-sanitize 字型驗證器",
    type = "custom",
    request = "launch",
    program = program_ots_sanitize,
  },
  {
    name = "ots-idempotent 字型轉碼穩定性檢查器",
    type = "custom",
    request = "launch",
    program = program_ots_idempotent,
  },
  {
    name = "ots-validator-checker 惡意字型驗證測試工具",
    type = "custom",
    request = "launch",
    program = program_ots_validator,
  },
  {
    name = "ots-side-by-side 渲染比對工具",
    type = "custom",
    request = "launch",
    program = program_ots_side_by_side,
  },
  {
    name = "ots-perf 轉碼效能測試工具",
    type = "custom",
    request = "launch",
    program = program_ots_perf,
  },
  {
    name = "ots batch run: {sanitize, idempotent, validator}",
    type = "custom",
    request = "launch",
    program = program_ots_batch_run,
  },
}
