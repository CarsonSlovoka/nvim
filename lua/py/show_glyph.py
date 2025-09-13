# python show_glyph.py ~/.fonts/my.otf --glyph_indice '[[1, 200], [500, 600]]'
# python show_glyph.py ~/.fonts/my.otf --glyph_indice '[]'
# python show_glyph.py ~/.fonts/my.otf --show_outline --glyph_indice [[1,200],[500,600]]  # WARN: 👈 如果要在nvim debug glyph_indice中有多的空白要拿掉

import argparse
import base64
import csv
import io
import json
import os
import sys
from typing import Any

import freetype  # pip install freetype-py==2.5.1
from fontTools.ttLib import TTFont  # pip install fonttools==4.59.2
from fontTools.ttLib.tables._c_m_a_p import table__c_m_a_p
from fontTools.ttLib.tables._m_a_x_p import table__m_a_x_p
from freetype.ft_enums.ft_curve_tags import (
    FT_Curve_Tag_Conic,
    FT_Curve_Tag_Cubic,
    FT_Curve_Tag_On,
)
from PIL import Image

parser = argparse.ArgumentParser(description="glyph information")
parser.add_argument("font_path", type=str, help="opentype fontpath")
parser.add_argument(
    "--show_outline",
    action="store_true",  # maeans it's a flag # 指如果旗標設定後要採取的動作
    help="print outline (for kitty terminal) (default: False)",  # 預設值與store的相反
)
parser.add_argument(
    "--glyph_indice",
    "-r",
    default="[]",
    help="[[start, end]...] ex: [[1, 200], [500, 600]]",
)
parser.add_argument(
    "--blocks_txt_path",
    type=str,
    default="",
    help="https://www.unicode.org/Public/draft/ucd/Blocks.txt",
)
args = parser.parse_args()

BLOCK_TXT_PATH = args.blocks_txt_path
if BLOCK_TXT_PATH == "":
    BLOCK_TXT_PATH = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "./ucd/db/Blocks.txt"
    )  # WARN: 從neovim來呼叫，__file__會不曉得

    if not os.path.exists(BLOCK_TXT_PATH):
        print(f"'{BLOCK_TXT_PATH}' not exists.")
        exit(11)  # b


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


class Point:
    def __init__(self, xy: tuple):
        self.x = xy[0]
        self.y = xy[1]


class GlyphRenderer:
    """用於將字型檔案的 glyph 渲染為 Kitty 終端機圖形控制序列的類"""

    def __init__(self, font_path, **kwargs):
        """初始化字型檔案並創建 FreeType Face 物件"""
        try:
            self.face = freetype.Face(font_path)
            self.face.set_char_size(kwargs.get("width", 96) * kwargs.get("height", 96))
            self.mimetype = kwargs.get("mimetype", "image/svg+xml")
            self.precision = kwargs.get("precision", 1)
        except Exception as e:
            raise ValueError(f"Failed to initialize font at {font_path}: {str(e)}")

    def get_glyph_svg(self, glyph: freetype.GlyphSlot) -> str:
        outline = glyph.outline
        if outline.n_points == 0:
            return ""

        # 計算 max_y 用於翻轉並偏移
        points = outline.points
        max_y = max(p[1] for p in points) if points else 0

        # 準備 SVG 路徑數據
        path_data = []
        current_pos = None  # 追蹤當前位置，避免重複

        def scale(x, y):
            # return x / 64.0, (max_y - y) / 64.0
            # return 8.0 * x, 8.0 * (max_y - y)
            return x, (max_y - y)

        def move_to(to, user):
            nonlocal current_pos
            tx, ty = scale(to.x, to.y)
            user.append(f"M {tx:.{self.precision}f} {ty:.{self.precision}f} ")
            current_pos = (tx, ty)

        def line_to(to, user):
            nonlocal current_pos
            tx, ty = scale(to.x, to.y)
            if (tx, ty) != current_pos:  # 避免重複
                user.append(f"L {tx:.{self.precision}f} {ty:.{self.precision}f} ")
            current_pos = (tx, ty)

        def conic_to(control, to, user):
            nonlocal current_pos
            cx, cy = scale(control.x, control.y)
            tx, ty = scale(to.x, to.y)
            user.append(
                f"Q {cx:.{self.precision}f} {cy:.{self.precision}f} {tx:.{self.precision}f} {ty:.{self.precision}f} "
            )
            current_pos = (tx, ty)

        def cubic_to(control1, control2, to, user):
            nonlocal current_pos
            c1x, c1y = scale(control1.x, control1.y)
            c2x, c2y = scale(control2.x, control2.y)
            tx, ty = scale(to.x, to.y)
            user.append(
                f"C {c1x:.{self.precision}f} {c1y:.{self.precision}f} {c2x:.{self.precision}f} {c2y:.{self.precision}f} {tx:.{self.precision}f} {ty:.{self.precision}f} "
            )
            current_pos = (tx, ty)

        # 使用 decompose 分解輪廓 ( 就不需要處理 FT_Curve_Tag_Conic, FT_Curve_Tag_Cubic, FT_Curve_Tag_On )
        outline.decompose(
            move_to=move_to,
            line_to=line_to,
            conic_to=conic_to,
            cubic_to=cubic_to,
            context=path_data,  # user 是 context，這裡用 list 收集
        )

        # 如果有輪廓，添加 Z 關閉最後一個輪廓
        if path_data:
            path_data.append("Z ")

        svg_path_data = "".join(path_data)
        # return svg_path_data

        # 可選：計算 bbox 並返回完整 SVG
        bbox = outline.get_bbox()
        xmin, ymin = scale(bbox.xMin, bbox.yMax)  # 注意翻轉
        xmax, ymax = scale(bbox.xMax, bbox.yMin)
        width = xmax - xmin
        height = ymax - ymin
        full_svg = f'<svg viewBox="{xmin:.{self.precision}f} {ymin:.{self.precision}f} {width:.{self.precision}f} {height:.{self.precision}f}" xmlns="http://www.w3.org/2000/svg"><path d="{svg_path_data}"/></svg>'
        return full_svg

    def render_glyph_to_kitty(self, glyph_index) -> str:
        """將指定 glyph index 渲染為 Kitty 終端機圖形控制序列"""
        try:
            self.face.load_glyph(glyph_index, getattr(freetype, "FT_LOAD_RENDER"))
            bitmap = self.face.glyph.bitmap
            width, rows = bitmap.width, bitmap.rows
            if width == 0 or rows == 0:
                return ""  # glyph無效

            b64 = ""
            mimetype: str = self.mimetype
            if mimetype == "image/svg+xml":
                # 獲取字形的 SVG 數據
                svg_data = self.get_glyph_svg(self.face.glyph)
                # print(svg_data)
                if not svg_data:
                    raise ValueError("無法生成 SVG 數據")

                svg_bytes = svg_data.encode("utf-8")
                b64 = base64.b64encode(svg_bytes).decode("utf-8")

            else:
                mimetype = "image/png"
                data = bytes(bitmap.buffer)
                img = Image.frombytes("L", (width, rows), data)  # gray mode

                # 轉成 PNG bytes
                buf = io.BytesIO()
                img.save(buf, format="PNG")
                png_data = buf.getvalue()
                b64 = base64.b64encode(png_data).decode("ascii")

            # 以下可行，但是想要直接寫入base64, 透過 [image.nvim](https://github.com/3rd/image.nvim) 來渲染，如此可以在編輯中也能看到圖
            # chunk_size = 4096
            # output = []
            # for i in range(0, len(b64), chunk_size):
            #     chunk = b64[i : i + chunk_size]
            #     m = 1 if i + chunk_size < len(b64) else 0
            #     output.append(f"\033_Gf=100,a=T,m={m};{chunk}\033\\")
            # return "".join(output)

            # https://github.com/3rd/image.nvim/issues/135
            # https://github.com/3rd/image.nvim/pull/241/files
            return f"![{glyph_index}](data:{mimetype};base64,{b64})"

        except Exception as e:
            return f"❌ Error rendering glyph {glyph_index}: {str(e)}"


def expand_ranges_to_array(ranges):
    """
    將範圍列表展開為單一陣列
    :param ranges: 範圍列表，如 [["100", "200"], ["50", "88"], ...]
    :return: 包含所有範圍內整數的集合（去重複）
    """

    if len(ranges) == 0 or ranges == "[]":
        return set()
    result = set()
    try:
        for start, end in ranges:
            start_num = int(start)
            end_num = int(end)
            result.update(range(start_num, end_num + 1))  # 包含 end
    except (ValueError, TypeError) as e:
        print("錯誤：範圍列表格式不正確或包含無效數字")
        raise (e)
    return result


def main(font_path, show_outline: bool, glyph_index=[]):
    font: Any = TTFont(font_path)

    target_glyph_index_set = expand_ranges_to_array(glyph_index)

    cmap: table__c_m_a_p = font["cmap"]
    maxp: table__m_a_x_p = font["maxp"]

    glyph_order = font.getGlyphOrder()

    header = [
        "gid",
        "glyphName",
        "isUnicode",
        "unicode_codepoint",
        "unicode_ch",
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
    glyph_render = GlyphRenderer(font_path, width=48, height=48)

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
                row["unicode_codepoint"] = f"U+{unicode_point:04x}"
                row["unicode_ch"] = chr(unicode_point)
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

main(args.font_path, args.show_outline, json.loads(args.glyph_indice))
