"""Generate deterministic Google Play assets from the approved FreshTrack logo."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


FEATURE_SIZE = (1024, 500)
STORE_ICON_SIZE = (512, 512)


def _cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_ratio = size[0] / size[1]
    source_ratio = image.width / image.height
    if source_ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        image = image.crop((left, 0, left + width, image.height))
    else:
        height = round(image.width / target_ratio)
        top = (image.height - height) // 2
        image = image.crop((0, top, image.width, top + height))
    return image.resize(size, Image.Resampling.LANCZOS)


def _font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    filename = "segoeuib.ttf" if bold else "segoeui.ttf"
    windows_font = Path("C:/Windows/Fonts") / filename
    if windows_font.exists():
        return ImageFont.truetype(str(windows_font), size)
    return ImageFont.truetype("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf", size)


def generate(background: Path, logo: Path, icon_source: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)

    feature = _cover(Image.open(background).convert("RGB"), FEATURE_SIZE)
    overlay = Image.new("RGBA", FEATURE_SIZE, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rounded_rectangle(
        (54, 72, 970, 428),
        radius=42,
        fill=(3, 12, 34, 112),
        outline=(90, 154, 255, 70),
        width=2,
    )
    feature = Image.alpha_composite(feature.convert("RGBA"), overlay)

    mark = Image.open(logo).convert("RGBA")
    mark.thumbnail((270, 270), Image.Resampling.LANCZOS)
    feature.alpha_composite(mark, (86, (FEATURE_SIZE[1] - mark.height) // 2))

    draw = ImageDraw.Draw(feature)
    draw.text((390, 143), "FreshTrack", font=_font(76, bold=True), fill="#F7FAFF")
    draw.text(
        (394, 238),
        "Scadenze sotto controllo.",
        font=_font(32, bold=True),
        fill="#9FC3FF",
    )
    draw.text(
        (394, 286),
        "Dati sempre sul dispositivo.",
        font=_font(28),
        fill="#D8E4F8",
    )
    draw.text(
        (394, 346),
        "Offline-first  •  Privata  •  Senza account",
        font=_font(20),
        fill="#74E3A2",
    )
    feature.convert("RGB").save(
        output / "feature-graphic-1024x500.png",
        format="PNG",
        optimize=True,
    )

    store_icon = Image.open(icon_source).convert("RGBA").resize(
        STORE_ICON_SIZE,
        Image.Resampling.LANCZOS,
    )
    store_icon.save(
        output / "play-store-icon-512.png",
        format="PNG",
        optimize=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--background", type=Path, required=True)
    parser.add_argument("--logo", type=Path, required=True)
    parser.add_argument("--icon-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    generate(args.background, args.logo, args.icon_source, args.output)


if __name__ == "__main__":
    main()
