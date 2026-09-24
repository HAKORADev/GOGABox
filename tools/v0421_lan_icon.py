#!/usr/bin/env python3
"""v042-1: rasterize the LAN seat icon (svg master -> the PNG the buttons ride)."""
import cairosvg

SRC = "/home/z/my-project/gogabox/projects/gogabox/assets/ui/icon_lan.svg"
DST = "/home/z/my-project/gogabox/projects/gogabox/assets/ui/icon_lan.png"

# 256px master - the buttons render it at 40 design px, crisp on any dpi
cairosvg.svg2png(url=SRC, write_to=DST, output_width=256, output_height=256)
print("wrote", DST)
