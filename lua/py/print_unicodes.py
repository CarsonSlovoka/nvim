# python print_unicodes.py ~/my.ttf
# python print_unicodes.py ~/my.ttf -c=50
# python print_unicodes.py ~/my.ttx --col=30
# python print_unicodes.py $(find ~/.fonts/*.{ttf,otf} | head -n 1) --col 30

import argparse
import io
import os
import sys
from typing import Any

from fontTools.ttLib import TTFont  # pip install fonttools==4.59.2
from fontTools.ttLib.tables._c_m_a_p import table__c_m_a_p

parser = argparse.ArgumentParser(description="list all unicode")
parser.add_argument("font_path", type=str, help="opentype fontpath")
parser.add_argument(
    "--col",
    "-c",
    type=int,
    default=10,
    help="How many columns are there for each column",
)

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")  # print輸出在stdout


def main(args):
    font: Any = TTFont(os.path.expanduser(args.font_path))
    cmap: table__c_m_a_p = font["cmap"]

    subtable = cmap.getBestCmap()
    if subtable is None:
        print("❌ The child table of unicode is not present in cmap")
        exit(1)

    msg = ""
    for i, (codepoint, glyph_name) in enumerate(subtable.items()):
        msg += chr(codepoint)
        if i != 0 and i % args.col == 0:
            print(msg)
            msg = ""


main(parser.parse_args())
