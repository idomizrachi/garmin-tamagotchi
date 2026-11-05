#!/usr/bin/env python3
"""Slice the generated sheet into aligned, palette-limited compiler resources.

ImageMagick performs mechanical grid extraction and nearest-neighbor reduction;
the original generated artwork remains in assets/source for reproducibility.
"""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "assets/source/companion-sheet.png"
NAMES = ["Idle", "Blink", "Wave", "Stretch", "Coffee", "Sip", "Walk", "Run",
         "Strength", "Celebrate", "Water", "Sleep"]


def run(*args):
    subprocess.run(["magick", *map(str, args)], check=True)


def main():
    dimensions = subprocess.check_output(
        ["magick", "identify", "-format", "%w %h", str(SHEET)], text=True)
    width, height = map(int, dimensions.split())
    for folder, canvas, body in [("resources/drawables", "144x160", "116x140"),
                                 ("resources-small/drawables", "124x137", "100x120")]:
        destination = ROOT / folder
        destination.mkdir(parents=True, exist_ok=True)
        for index, name in enumerate(NAMES):
            column, row = index % 4, index // 4
            x0, x1 = round(column * width / 4), round((column + 1) * width / 4)
            y0, y1 = round(row * height / 3), round((row + 1) * height / 3)
            run(SHEET, "-crop", f"{x1-x0}x{y1-y0}+{x0}+{y0}", "+repage",
                "-channel", "A", "-threshold", "55%", "+channel", "-trim", "+repage",
                "-filter", "point", "-resize", body, "-background", "none",
                "-gravity", "south", "-extent", canvas, "+dither", "-colors", "31",
                "PNG8:" + str(destination / f"{name}.png"))
        run(destination / "Sleep.png", "-trim", "+repage", "-filter", "point",
            "-resize", "36x28", "-channel", "RGB", "-evaluate", "multiply", "0.30",
            "+channel", "+dither", "-colors", "15", "PNG8:" + str(destination / "AodSleep.png"))
        icon_size = "54x54" if "small" in folder else "65x65"
        icon_body = "46x46" if "small" in folder else "55x55"
        run(destination / "Idle.png", "-trim", "+repage", "-filter", "point", "-resize",
            icon_body, "-gravity", "center", "-background", "none", "-extent", icon_size,
            "PNG8:" + str(destination / "LauncherIcon.png"))
        entries = NAMES + ["AodSleep", "LauncherIcon"]
        xml = '<drawables>\n' + ''.join(
            f'  <bitmap id="{n}" filename="{n}.png" dithering="none"/>\n' for n in entries) + '</drawables>\n'
        (destination / "drawables.xml").write_text(xml)


if __name__ == "__main__":
    main()
