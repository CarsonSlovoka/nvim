# python show_glyph.py

import base64
import csv
import io
import os
import sys
from typing import Any

import freetype  # pip install freetype-py==2.5.1
from fontTools.ttLib import TTFont  # pip install fonttools==4.59.2
from fontTools.ttLib.tables._c_m_a_p import table__c_m_a_p
from fontTools.ttLib.tables._m_a_x_p import table__m_a_x_p
from PIL import Image

font_path = "%s"
font: Any = TTFont(font_path)

BLOCK_TXT_PATH = "%s"
# BLOCK_TXT_PATH = os.path.join( os.path.dirname(os.path.dirname(__file__)), "./ucd/db/Blocks.txt") # WARN: 從neovim來呼叫，__file__會不曉得


def load_unicode_blocks():
    # print(BLOCK_TXT_PATH)
    blocks = []
    with open(BLOCK_TXT_PATH, "r", encoding="utf-8") as f:
        for line in f:
            # 跳過註釋行和空行
            if line.startswith("#") or not line.strip():
                continue
            # 格式例：0000..007F; Basic Latin
            range_part, name = line.strip().split("; ")
            start, end = range_part.split("..")
            blocks.append({"start": int(start, 16), "end": int(end, 16), "name": name})
    return blocks


def get_unicode_block_name(codepoint, blocks):
    codepoint = int(codepoint, 16) if isinstance(codepoint, str) else codepoint
    for block in blocks:
        if block["start"] <= codepoint <= block["end"]:
            return block["name"]
    return "No Block Defined"


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
        "block",
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

    blocks = load_unicode_blocks()
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
                row["block"] = get_unicode_block_name(unicode_point, blocks)

        if show_outline:
            row["outline"] = glyph_render.render_glyph_to_kitty(
                gid
            )  # nvim 沒辦法做，再外層的終端機可以

        writer.writerow(row)


# codepoint測試
# blocks = load_unicode_blocks()
# test_codepoints = ["0x0251", "0x0041", "0xFFFF"]
# for cp in test_codepoints:
#     print(f"Codepoint {cp}: {get_unicode_block_name(cp, blocks)}")

# main(％s, ％s)
