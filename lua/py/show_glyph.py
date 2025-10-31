# python show_glyph.py ~/.fonts/my.otf --glyph_indice '[[1, 200], [500, 600]]'
# python show_glyph.py ~/.fonts/my.otf --glyph_indice '[]'
# python show_glyph.py ~/.fonts/my.otf --show_outline --glyph_indice [[1,200],[500,600]]  # WARN: 👈 如果要在nvim debug glyph_indice中有多的空白要拿掉
# python show_glyph.py ~/.fonts/my.otf --mimetype=kgp -w=96 --height=96 --precision=3 --show_outline --glyph_indice [[1,200],[500,600]]
# python show_glyph.py ~/.fonts/my.otf --mimetype=svg --precision=0 --show_outline --glyph_indice [[1,200],[500,600]]
# python show_glyph.py ~/.fonts/my.otf --mimetype=html --precision=0 --show_outline --glyph_indice [[1,200],[500,600]]


import argparse
import base64
import csv
import io
import json
import os
import sys
from dataclasses import dataclass
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
from PIL import Image # pip install pillow==12.0.0

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
parser.add_argument(
    "--mimetype",
    type=str,
    default="image/svg+xml",
    help="image/svg+xml, image/png, kgp, svg, html",
)
parser.add_argument(
    "--precision",
    type=int,
    default=1,
    help=".1f, .2f, ...",
)
parser.add_argument(
    "--width",  # parse_args() 之後要用的名稱, 即: args.width
    "-w",  # 這個名稱只能當成輸入，不能: args.w
    type=int,
    default=48,
    help="img width: 48, 96, ...",
)
parser.add_argument(
    "--height",
    # "-h", # argument -h: conflicting option string: -h 會與幫助衝突
    type=int,
    default=48,
    help="img height: 48, 96, ...",
)
args = parser.parse_args()
# print(args)

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


@dataclass
class PointData:
    x: float
    y: float
    type: str
    color: str
    idx: int  # base-index: 1, 因為都是先push才取所有index從1開始


# 此HTML可以拖曳點
HTML_TEMPLATE = """
<head>
  <meta charset="UTF-8">
  <title>%s</title>
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <style>
    svg {
      border: 1px solid #ccc;
      cursor: move;
    }
    circle {
      cursor: pointer;
    }

    .control-panel {
      margin: 20px;
      padding: 10px;
      border: 1px solid #ccc;
      display: inline-block;
    }
    .control-panel label {
      margin-right: 10px;
    }
    .control-panel input {
      margin-bottom: 10px;
    }
  </style>
</head>

<body>
  <h1>%s</h1>
  <div class="control-panel">
    <div>
      <label>SVG Width: <input type="number" id="svg-width" value="800"></label>
    </div>
    <div>
      <label>SVG Height: <input type="number" id="svg-height" value="800"></label>
    </div>
    <div>
      <label>Stroke Width: <input type="range" id="stroke-width" min="0" max="16" step="0.1" value="3"></label>
      <span id="stroke-width-value">3</span>
    </div>
    <div>
      <label>Circle Fill Opacity: <input type="range" id="circle-opacity" min="0" max="1" step="0.05" value="0.75"></label>
      <span id="circle-opacity-value">0.75</span>
    </div>
    <div>
      <label>Text Fill Opacity: <input type="range" id="text-opacity" min="0" max="1" step="0.05" value="1"></label>
      <span id="text-opacity-value">1</span>
    </div>
    <div>
      <label>Font Size: <input type="number" id="font-size" min="1" value="78"></label>
    </div>
    <div>
      <label>Circle Radius: <input type="range" id="circle-radius" min="1" max="50" step="0.5" value="6"></label>
      <span id="circle-radius-value">6</span>
    </div>
    <div>
      <label>Fill Color: <input type="color" id="fill-color" value="#ffc600"></label>
    </div>
    <div>
      <label>Stroke Color: <input type="color" id="stroke-color" value="#000000"></label>
    </div>
    <div>
      <label>Data Index Filter (e.g., 1..10,18..21): <input type="text" id="data-idx-filter"
          placeholder="e.g., 1..10,18..21"></label>
    </div>
    <div>
      <label>Filter circles: <input type="checkbox" id="circles-filter-toggle"></label>
    </div>

    <div>
      <label>Enable Data Type Filter: <input type="checkbox" id="type-filter-toggle" checked></label>
    </div>
    <div id="type-group" class="checkbox-group">
      <label>Data Type Filter:</label>
      <label><input type="checkbox" id="type-move" value="move" checked> Move</label>
      <label><input type="checkbox" id="type-line" value="line" checked> Line</label>
      <label><input type="checkbox" id="type-cubic" value="cubic" checked> Cubic</label>
      <label><input type="checkbox" id="type-conic" value="conic" checked> Conic</label>
    </div>
  </div>
  %s
</body>

<script>
  const svg = d3.select("svg")
  const path = svg.select("path")
  const circles = svg.selectAll("circle")
  const texts = svg.selectAll("text")

  // 控制面版
  const svgWidthInput = d3.select("#svg-width")
  const svgHeightInput = d3.select("#svg-height")
  const strokeWidthInput = d3.select("#stroke-width")
  const strokeWidthValue = d3.select("#stroke-width-value")
  const circleOpacityInput = d3.select("#circle-opacity")
  const circleOpacityValue = d3.select("#circle-opacity-value")
  const textOpacityInput = d3.select("#text-opacity")
  const textOpacityValue = d3.select("#text-opacity-value")
  const fontSizeInput = d3.select("#font-size")
  const circleRadiusInput = d3.select("#circle-radius")
  const circleRadiusValue = d3.select("#circle-radius-value")
  const fillColorInput = d3.select("#fill-color")
  const strokeColorInput = d3.select("#stroke-color")

  const dataIdxFilterInput = d3.select("#data-idx-filter")
  const circlesFilterInput = d3.select("#circles-filter-toggle")

  const typeFilterToggle = d3.select("#type-filter-toggle")
  const typeMoveInput = d3.select("#type-move")
  const typeLineInput = d3.select("#type-line")
  const typeCubicInput = d3.select("#type-cubic")
  const typeConicInput = d3.select("#type-conic")

  // Update SVG width, height
  svgWidthInput.on("input", function () {
    svg.attr("width", this.value)
  })
  svgHeightInput.on("input", function () {
    svg.attr("height", this.value)
  })

  // Update stroke width
  strokeWidthInput.on("input", function () {
    svg.select("g").attr("stroke-width", this.value)
    strokeWidthValue.text(this.value)
  })

  // Update circle fill-opacity
  circleOpacityInput.on("input", function () {
    svg.select("g[aria-label] g").attr("fill-opacity", this.value)
    circleOpacityValue.text(this.value)
  })

  // Update text fill-opacity
  textOpacityInput.on("input", function () {
    svg.select("g[aria-label] g[font-size]").attr("fill-opacity", this.value)
    textOpacityValue.text(this.value)
  })

  // Update font size
  fontSizeInput.on("input", function() {
    svg.select("g[aria-label] g[font-size]").attr("font-size", this.value)
  })

  // Update circle radius
  circleRadiusInput.on("input", function() {
    svg.selectAll("circle").attr("r", this.value)
    circleRadiusValue.text(this.value)
  })

  // Update fill color
  fillColorInput.on("input", function() {
    svg.select("g").attr("fill", this.value)
  })

  // Update stroke color
  strokeColorInput.on("input", function() {
    svg.select("g").attr("stroke", this.value)
  })


  // Parse data-idx filter
  function parseIdxFilter(input) {
    if (!input) return null
    const ranges = input.split(",").map(s => s.trim())
    const indices = new Set()
    ranges.forEach(range => {
      if (range.includes("..")) {
        const [start, end] = range.split("..").map(Number)
        for (let i = start; i <= end; i++) {
          indices.add(i)
        }
      } else {
        indices.add(Number(range))
      }
    })
    return indices
  }

  // 過濾要呈現的data-idx對像
  dataIdxFilterInput.on("input", function () {
    const indices = parseIdxFilter(this.value)
    circles.each(function () {
      const idx = Number(d3.select(this).attr("data-idx"))
      d3.select(this).style("display", indices && !indices.has(idx) ? "none" : null)
    })

    // 雖然text沒有data-idx, 但是它是按照順序寫的
    texts.each(function () {
      const textIdx = Number(this.textContent)
      d3.select(this).style("display", indices && !indices.has(textIdx) ? "none" : null)
    })
    updatePath()
  })

  // Parse data-type filter from checkboxes
  function parseTypeFilter() {
    const types = []
    if (typeMoveInput.property("checked")) types.push("move")
    if (typeLineInput.property("checked")) types.push("line")
    if (typeCubicInput.property("checked")) types.push("cubic")
    if (typeConicInput.property("checked")) types.push("conic")
    return types.length > 0 ? new Set(types) : null
  }

  // Update visibility based on data-idx and data-type filters
  function updateVisibility() {
    const idxFilter = parseIdxFilter(dataIdxFilterInput.property("value"))
    const typeFilter = typeFilterToggle.property("checked") ? parseTypeFilter() : null

    circles.each(function() {
      const idx = Number(d3.select(this).attr("data-idx"))
      const type = d3.select(this).attr("data-type").toLowerCase()
      const idxVisible = !idxFilter || idxFilter.has(idx)
      const typeVisible = !typeFilter || typeFilter.has(type)
      d3.select(this).style("display", idxVisible && typeVisible ? null : "none")
    })

    texts.each(function() {
      const textIdx = Number(this.textContent)
      const idxVisible = !idxFilter || idxFilter.has(textIdx)
      const typeVisible = !typeFilter || circles.filter(function() {
        return Number(d3.select(this).attr("data-idx")) === textIdx
      }).nodes().some(node => typeFilter.has(d3.select(node).attr("data-type").toLowerCase()))
      d3.select(this).style("display", idxVisible && typeVisible ? null : "none")
    })

    updatePath()
  }

  // Attach input listeners for filters
  dataIdxFilterInput.on("input", updateVisibility)
  circlesFilterInput.on("change", updateVisibility)
  typeFilterToggle.on("change", (e) => {
    document.querySelector("#type-group").querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.disabled = !e.target.checked
    })
    updateVisibility()
  })
  typeMoveInput.on("change", updateVisibility)
  typeLineInput.on("change", updateVisibility)
  typeCubicInput.on("change", updateVisibility)
  typeConicInput.on("change", updateVisibility)


  // 附加拖曳行為
  circles.call(d3.drag()
    .on("start", function () {
      d3.select(this).raise().classed("active", true)
    })
    .on("drag", function (event) {
      const circle = d3.select(this)
      circle.attr("cx", event.x).attr("cy", event.y)

      // 更新對應的 text（假設 circles 和 texts 順序相同）
      const index = circles.nodes().indexOf(this)
      const correspondingText = d3.select(texts.nodes()[index])
      correspondingText.attr("x", event.x).attr("y", event.y + 5) // 可選偏移 y 以避免完全重疊

      // 更新 path
      updatePath()
    })
    .on("end", function () {
      d3.select(this).classed("active", false)
    })
  )

  // 更新 path 的 d 屬性
  function updatePath() {
    let pathD = ""
    let i = 0
    const circleNodes = circlesFilterInput.property("checked") ?
      circles.nodes().filter(node => d3.select(node).style("display") !== "none") :
      circles.nodes();


    while (i < circleNodes.length) {
      const circle = d3.select(circleNodes[i])
      const type = circle.attr("data-type")
      const cx = parseFloat(circle.attr("cx"))
      const cy = parseFloat(circle.attr("cy"))

      if (type === "move") {
        pathD += `M ${cx} ${cy} `
      } else if (type === "line") {
        pathD += `L ${cx} ${cy} `
      } else if (type === "conic") {
        // 第一個 conic 是控制點
        pathD += `Q ${cx} ${cy} `
        // 下一個是終點
        i++
        const nextCircle = d3.select(circleNodes[i])
        const nextCx = parseFloat(nextCircle.attr("cx"))
        const nextCy = parseFloat(nextCircle.attr("cy"))
        pathD += `${nextCx} ${nextCy} `
      } else if (type === "cubic") {
        pathD += `C ${cx} ${cy} ` // 控制點
        i++
        if (i < circleNodes.length) { // 確保index不會超出
          // 控制點
          const nextCircle1 = d3.select(circleNodes[i])
          const nextCx1 = parseFloat(nextCircle1.attr("cx"))
          const nextCy1 = parseFloat(nextCircle1.attr("cy"))
          pathD += `${nextCx1} ${nextCy1} `
          i++
          if (i < circleNodes.length) {
            // 終點
            const nextCircle2 = d3.select(circleNodes[i])
            const nextCx2 = parseFloat(nextCircle2.attr("cx"))
            const nextCy2 = parseFloat(nextCircle2.attr("cy"))
            pathD += `${nextCx2} ${nextCy2} `
          }
        }
      }

      i++
    }

    // 添加閉合 Z（根據原 path）
    pathD += "Z"

    path.attr("d", pathD)
  }
</script>
"""


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

    def get_glyph_svg(self, glyph: freetype.GlyphSlot, **options) -> str:
        outline = glyph.outline
        if outline.n_points == 0:
            return ""

        # 計算 max_y 用於翻轉並偏移
        points = outline.points
        max_y = max(p[1] for p in points) if points else 0

        # 準備 SVG 路徑數據
        path_data = []
        points_data: list[PointData] = []  # 儲存點的座標和類型
        current_pos = None  # 追蹤當前位置，避免重複

        def scale(x, y):
            # return x / 64.0, (max_y - y) / 64.0
            # return 8.0 * x, 8.0 * (max_y - y)
            return x, (max_y - y)  # 用max_y - y 是因為y座標系是相反的

        def move_to(to, user: list):  # user 是一個list, 可以自定義裡面的內容
            nonlocal current_pos
            tx, ty = scale(to.x, to.y)
            user.append(f"M {tx:.{self.precision}f} {ty:.{self.precision}f} ")
            points_data.append(
                PointData(tx, ty, "move", "#3d3d3d", len(points_data) + 1)
            )  # 移動點用黑色
            current_pos = (tx, ty)

        def line_to(to, user):
            nonlocal current_pos
            tx, ty = scale(to.x, to.y)
            if (tx, ty) != current_pos:  # 避免重複
                user.append(f"L {tx:.{self.precision}f} {ty:.{self.precision}f} ")
                points_data.append(
                    PointData(tx, ty, "line", "green", len(points_data) + 1)
                )  # 線段終點綠色
            current_pos = (tx, ty)

        def conic_to(control, to, user):
            nonlocal current_pos
            cx, cy = scale(control.x, control.y)
            tx, ty = scale(to.x, to.y)
            user.append(
                f"Q {cx:.{self.precision}f} {cy:.{self.precision}f} {tx:.{self.precision}f} {ty:.{self.precision}f} "
            )
            # 二次貝茲控制點顏色橘色
            points_data.append(
                PointData(cx, cy, "conic", "#ffa600", len(points_data) + 1)
            )

            # 結束點
            points_data.append(
                PointData(tx, ty, "conic", "#ffa6", len(points_data) + 1)
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
            # 三次貝茲控制點顏色紅色
            points_data.append(
                PointData(c1x, c1y, "cubic", "#ff1100", len(points_data) + 1)
            )
            points_data.append(
                PointData(c2x, c2y, "cubic", "#ff1100", len(points_data) + 1)
            )

            # 結束點
            points_data.append(
                PointData(tx, ty, "cubic", "#debe44", len(points_data) + 1)
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

        # 設定水平和垂直 padding 為 width 和 height 的 5%
        horizontal_padding = width * 0.05
        vertical_padding = height * 0.05

        # 調整 viewBox，增加留白
        viewBox_xmin = xmin - horizontal_padding
        viewBox_ymin = ymin - vertical_padding
        viewBox_width = width + 2 * horizontal_padding
        viewBox_height = height + 2 * vertical_padding

        # 生成 SVG 圓點
        svg_points = []
        svg_texts = []  # 標記是第幾個點
        for pd in points_data:
            r = max(width, height) * 0.003
            if pd.type == "move":
                r = r * 2  # 增加起始點的大小

            svg_points.append(
                (
                    f'<circle data-type="{pd.type}" data-idx="{pd.idx}" '
                    f'cx="{pd.x:.{self.precision}f}" cy="{pd.y:.{self.precision}f}" '
                    f'r="{r:.0f}" fill="{pd.color}"/>'
                )
            )
            svg_texts.append(
                (
                    f'<text x="{pd.x:.{self.precision}f}" y="{pd.y:.{self.precision}f}">'
                    f"{pd.idx}"
                    f"</text>"
                )
            )

        full_svg = (
            f'<svg width="" height="" '
            f'viewBox="{viewBox_xmin:.{self.precision}f} {viewBox_ymin:.{self.precision}f} {viewBox_width:.{self.precision}f} {viewBox_height:.{self.precision}f}" xmlns="http://www.w3.org/2000/svg">'
            f'\n<g fill-opacity="0.75" fill="#ffc600" stroke="{ "black" if options.get("show_label") else "none" }" stroke-width="3">\n  <path d="{svg_path_data}"/>\n</g>'
        )
        if options.get("show_label"):
            # image.nvim中對fill-opacity似乎沒有辦法，就算設定為0，都還是看的到, 所以如果不呈現就乾脆不寫
            full_svg += (
                f'\n<g aria-label="" fill-opacity="1">'  # 如果不想要circle, text 可以直接從這邊調整
                f'\n  <g fill-opacity="1">\n    {"\n    ".join(svg_points)}</g>'
                f'\n  <g fill-opacity="1" font-size="3em">\n    {"\n    ".join(svg_texts)}</g>'
                f"\n</g>"
            )
        return full_svg + "\n</svg>"

    def render_glyph(
        self,
        glyph_index: int,
        glyph_name: str,
        unicode="",
    ) -> str:
        """畫出指定的 glyph index 圖形"""
        try:
            self.face.load_glyph(glyph_index, getattr(freetype, "FT_LOAD_RENDER"))
            bitmap = self.face.glyph.bitmap
            width, rows = bitmap.width, bitmap.rows
            if width == 0 or rows == 0:
                return ""  # glyph無效

            b64 = ""
            mimetype: str = self.mimetype
            if mimetype == "image/svg+xml" or mimetype == "svg" or mimetype == "html":
                # 獲取字形的 SVG 數據
                svg_data = self.get_glyph_svg(
                    self.face.glyph, show_label=(True if mimetype == "html" else False)
                )

                if mimetype == "svg" or mimetype == "html":
                    # 輸出實體的svg資料，到/tmp去，如果 /tmp 用的是 tmpfs 的檔案系統也等同於在記憶體中操作
                    output_path = f"/tmp/glyph/{self.face.postscript_name.decode('utf-8')}/{glyph_index}.{mimetype}"  # 有的插件如live-preview.nvim需要明確的附檔名
                    os.makedirs(os.path.dirname(output_path), exist_ok=True)

                    content = ""
                    if mimetype == "svg":
                        content = svg_data
                    if mimetype == "html":
                        content = HTML_TEMPLATE % (
                            glyph_name,
                            f"{glyph_name} ({unicode})",
                            svg_data,
                        )
                    with open(output_path, "w") as f:
                        f.write(content)
                    return f"![{glyph_index}]({output_path})"

                # print(svg_data)
                if not svg_data:
                    raise ValueError("無法生成 SVG 數據")

                svg_bytes = svg_data.encode("utf-8")
                b64 = base64.b64encode(svg_bytes).decode("utf-8")

            else:  # 統一用png處理
                data = bytes(bitmap.buffer)
                img = Image.frombytes("L", (width, rows), data)  # gray mode

                # 轉成 PNG bytes
                buf = io.BytesIO()
                img.save(buf, format="PNG")
                png_data = buf.getvalue()
                b64 = base64.b64encode(png_data).decode("ascii")

                if mimetype == "kgp":
                    # 渲染為 Kitty 終端機圖形控制序列
                    chunk_size = 4096
                    output = []
                    for i in range(0, len(b64), chunk_size):
                        chunk = b64[i : i + chunk_size]
                        m = 1 if i + chunk_size < len(b64) else 0
                        output.append(f"\033_Gf=100,a=T,m={m};{chunk}\033\\")
                    return "".join(output)

                mimetype = "image/png"  # 強制設定成png

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
    glyph_render = GlyphRenderer(
        font_path,
        width=args.width,
        height=args.height,
        mimetype=args.mimetype,
        precision=args.precision,
    )

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
            row["outline"] = glyph_render.render_glyph(
                gid,
                row["glyphName"],
                row["unicode_codepoint"] if "unicode_codepoint" in row else "",
            )  # nvim 沒辦法做，再外層的終端機可以

        writer.writerow(row)


# codepoint測試
# blocks = load_unicode_blocks()
# test_codepoints = ["0x0251", "0x0041", "0xFFFF"]
# for cp in test_codepoints:
#     print(f"Codepoint {cp}: {get_unicode_block_name(cp, blocks)}")

# main(％s, ％s)

main(args.font_path, args.show_outline, json.loads(args.glyph_indice))
