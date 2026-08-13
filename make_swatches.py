#!/usr/bin/env python3
"""Renders a terminal-ANSI swatch strip PNG per custom family into
swatches/<family>.png -- bg/fg plus the 6 real ANSI colors
(red/green/yellow/blue/magenta/cyan) from each theme's own
[colors.normal] table, light and dark stacked. Re-run after editing
any config/alacritty/themes/<family>_{light,dark}.toml -- generated,
never hand-edited.
"""
import tomllib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

THEMES_DIR = Path(__file__).parent / "config" / "alacritty" / "themes"
OUT_DIR = Path(__file__).parent / "swatches"

FAMILIES = ("slate", "bonepaper", "flexoki", "martin", "cypress")
_ANSI = ("red", "green", "yellow", "blue", "magenta", "cyan")
_SWATCH = 60
_LABEL_H = 16
_PAD = 8
_MODE_COL_W = 44


def _font():
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",):
        if Path(path).exists():
            return ImageFont.truetype(path, 12)
    return ImageFont.load_default()


def _load(family: str, mode: str) -> dict:
    path = THEMES_DIR / f"{family}_{mode}.toml"
    with open(path, "rb") as f:
        return tomllib.load(f)


def render_family(family: str) -> Image.Image:
    font = _font()
    cols = ["bg", "fg"] + list(_ANSI)
    width = _MODE_COL_W + _PAD + len(cols) * (_SWATCH + _PAD)
    row_h = _SWATCH + _LABEL_H + _PAD
    height = _PAD + 2 * row_h
    img = Image.new("RGB", (width, height), "#ffffff")
    draw = ImageDraw.Draw(img)

    for row, mode in enumerate(("light", "dark")):
        data = _load(family, mode)
        primary = data["colors"]["primary"]
        normal = data["colors"]["normal"]
        values = {"bg": primary["background"], "fg": primary["foreground"]}
        values.update({k: normal[k] for k in _ANSI})
        y0 = _PAD + row * row_h
        draw.text((_PAD, y0 + _SWATCH // 2 - 6), mode, fill="#000000", font=font)
        for col, key in enumerate(cols):
            x0 = _MODE_COL_W + _PAD + col * (_SWATCH + _PAD)
            draw.rectangle([x0, y0, x0 + _SWATCH, y0 + _SWATCH], fill=values[key], outline="#999999")
            draw.text((x0, y0 + _SWATCH + 2), key, fill="#333333", font=font)
    return img


def main():
    OUT_DIR.mkdir(exist_ok=True)
    for family in FAMILIES:
        img = render_family(family)
        out_path = OUT_DIR / f"{family}.png"
        img.save(out_path)
        print(f"{family} -> {out_path.relative_to(Path(__file__).parent)}")


if __name__ == "__main__":
    main()
