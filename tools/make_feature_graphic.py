#!/usr/bin/env python3
"""Flamingo feature graphic (1024x500) — Play listing banner.

Run: python3 tools/make_feature_graphic.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store-assets" / "feature-1024x500.png"
ICON = ROOT / "assets" / "app-icon-1024.png"

FONT_BOLD = "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/TTF/DejaVuSans.ttf"

# Canon flamingo palette (lib/core/theme/flamingo_theme.dart)
BG_HI = "#1A0A2E"   # surface
BG_LO = "#0A0012"   # scaffoldBg
PINK = "#FF69B4"
CYAN = "#00D4FF"
GOLD = "#FFD700"
TEXT = "#F0E6FF"
MUTED = "#9B8ABF"


def vgrad(size, top, bottom) -> Image.Image:
    w, h = size
    im = Image.new("RGB", size)
    t = tuple(int(top[i:i + 2], 16) for i in (1, 3, 5))
    b = tuple(int(bottom[i:i + 2], 16) for i in (1, 3, 5))
    px = im.load()
    for y in range(h):
        f = y / max(h - 1, 1)
        row = tuple(round(t[c] + (b[c] - t[c]) * f) for c in range(3))
        for x in range(w):
            px[x, y] = row
    return im


def fit_font(text: str, max_w: int, start: int, path: str = FONT_BOLD):
    size = start
    while size > 12:
        f = ImageFont.truetype(path, size)
        if f.getbbox(text)[2] <= max_w:
            return f
        size -= 2
    return ImageFont.truetype(path, 12)


def main() -> None:
    W, H = 1024, 500
    im = vgrad((W, H), BG_HI, BG_LO).convert("RGBA")
    d = ImageDraw.Draw(im)

    # neon gradient accent bar, bottom (pink -> cyan)
    bar_h = 12
    for x in range(W):
        f = x / W
        c1 = tuple(int(PINK[i:i + 2], 16) for i in (1, 3, 5))
        c2 = tuple(int(CYAN[i:i + 2], 16) for i in (1, 3, 5))
        d.line([(x, H - bar_h), (x, H)],
               fill=tuple(round(c1[c] + (c2[c] - c1[c]) * f) for c in range(3)))

    # app icon, left third
    icon = Image.open(ICON).convert("RGBA").resize((320, 320), Image.LANCZOS)
    im.alpha_composite(icon, (80, (H - 320) // 2 - 6))

    # wordmark
    tx, max_w = 450, W - 450 - 30
    f_big = fit_font("FLAMINGO", max_w, 96)
    f_sub = fit_font("SWISS ARMY KNIFE", max_w, 36)
    tag = "30 offline tools  ·  no ads  ·  no accounts  ·  no internet"
    f_tag = fit_font(tag, max_w, 26, FONT_REG)
    y = 130
    d.text((tx, y), "FLAMINGO", font=f_big, fill=PINK)
    y += f_big.size + 18
    d.text((tx + 2, y), "SWISS ARMY KNIFE", font=f_sub, fill=CYAN)
    y += f_sub.size + 20
    d.text((tx + 2, y), tag, font=f_tag, fill=MUTED)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
