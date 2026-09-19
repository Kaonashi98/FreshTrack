"""Compose benefit-led Google Play screenshots from real FreshTrack screens."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


OUTPUT_SIZE = (1080, 2400)
SCREEN_WIDTH = 820
SCREEN_TOP = 550


@dataclass(frozen=True)
class ScreenshotSpec:
    source: Path
    filename: str
    title: str
    subtitle: str


def _font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    filename = "segoeuib.ttf" if bold else "segoeui.ttf"
    windows_font = Path("C:/Windows/Fonts") / filename
    if windows_font.exists():
        return ImageFont.truetype(str(windows_font), size)
    fallback = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    return ImageFont.truetype(fallback, size)


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


def _wrap(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if not current or draw.textbbox((0, 0), candidate, font=font)[2] <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def _draw_lines(
    draw: ImageDraw.ImageDraw,
    lines: list[str],
    *,
    x: int,
    y: int,
    font: ImageFont.FreeTypeFont,
    fill: str,
    spacing: int,
) -> int:
    line_height = font.size + spacing
    for index, line in enumerate(lines):
        draw.text((x, y + index * line_height), line, font=font, fill=fill)
    return y + len(lines) * line_height


def _rounded_screen(source: Path) -> Image.Image:
    image = Image.open(source).convert("RGB")
    height = round(image.height * SCREEN_WIDTH / image.width)
    image = image.resize((SCREEN_WIDTH, height), Image.Resampling.LANCZOS)
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width, image.height),
        radius=46,
        fill=255,
    )
    rounded = Image.new("RGBA", image.size)
    rounded.paste(image, mask=mask)
    return rounded


def _compose(background: Image.Image, spec: ScreenshotSpec) -> Image.Image:
    canvas = _cover(background.copy(), OUTPUT_SIZE).convert("RGBA")
    shade = Image.new("RGBA", OUTPUT_SIZE, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    shade_draw.rectangle((0, 0, 1080, 540), fill=(3, 12, 31, 90))
    canvas = Image.alpha_composite(canvas, shade)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle(
        (70, 66, 326, 126),
        radius=30,
        fill=(110, 165, 255, 38),
        outline=(126, 177, 255, 125),
        width=2,
    )
    draw.text((103, 77), "FRESHTRACK", font=_font(25, bold=True), fill="#A9CBFF")

    title_font = _font(68, bold=True)
    subtitle_font = _font(33)
    title_lines = _wrap(draw, spec.title, title_font, 940)
    title_bottom = _draw_lines(
        draw,
        title_lines,
        x=70,
        y=154,
        font=title_font,
        fill="#F7FAFF",
        spacing=12,
    )
    subtitle_lines = _wrap(draw, spec.subtitle, subtitle_font, 930)
    _draw_lines(
        draw,
        subtitle_lines,
        x=73,
        y=title_bottom + 18,
        font=subtitle_font,
        fill="#C8D7EE",
        spacing=13,
    )

    screen = _rounded_screen(spec.source)
    screen_x = (OUTPUT_SIZE[0] - screen.width) // 2
    shadow = Image.new("RGBA", OUTPUT_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            screen_x - 28,
            SCREEN_TOP - 28,
            screen_x + screen.width + 28,
            SCREEN_TOP + screen.height + 28,
        ),
        radius=70,
        fill=(0, 0, 0, 175),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    canvas = Image.alpha_composite(canvas, shadow)
    frame_draw = ImageDraw.Draw(canvas)
    frame_draw.rounded_rectangle(
        (
            screen_x - 16,
            SCREEN_TOP - 16,
            screen_x + screen.width + 16,
            SCREEN_TOP + screen.height + 16,
        ),
        radius=60,
        fill="#030B18",
        outline=(119, 170, 255, 110),
        width=3,
    )
    canvas.alpha_composite(screen, (screen_x, SCREEN_TOP))
    return canvas.convert("RGB")


def generate(
    background_path: Path,
    output: Path,
    root: Path,
    language: str,
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    background = Image.open(background_path).convert("RGB")
    italian_specs = [
        ScreenshotSpec(
            source=root / "docs/screenshots/dashboard.png",
            filename="01-sai-cosa-usare-prima.png",
            title="Sai cosa usare prima",
            subtitle="Le scadenze più vicine restano sempre in primo piano.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/products.png",
            filename="02-trova-tutto-al-volo.png",
            title="Trova tutto al volo",
            subtitle="Cerca, filtra e aggiorna ogni prodotto in pochi tocchi.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/source-current/quick-add.png",
            filename="03-aggiungi-in-pochi-secondi.png",
            title="Aggiungi in pochi secondi",
            subtitle="Nome e scadenza bastano. Barcode e foto sono facoltativi.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/source-current/data-backup.png",
            filename="04-inventario-al-sicuro.png",
            title="Proteggi il tuo inventario",
            subtitle="Crea un backup completo con prodotti, preferenze e foto.",
        ),
    ]
    english_specs = [
        ScreenshotSpec(
            source=root / "docs/screenshots/source-release-en/dashboard.png",
            filename="01-know-what-to-use-first.png",
            title="Know what to use first",
            subtitle="The closest expiration dates always stay in focus.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/source-release-en/products.png",
            filename="02-find-everything-fast.png",
            title="Find everything fast",
            subtitle="Search, filter and update every product in a few taps.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/source-release-en/quick-add.png",
            filename="03-add-in-seconds.png",
            title="Add items in seconds",
            subtitle="A name and date are enough. Barcode and photos are optional.",
        ),
        ScreenshotSpec(
            source=root / "docs/screenshots/source-release-en/data-backup.png",
            filename="04-keep-inventory-safe.png",
            title="Keep your inventory safe",
            subtitle="Create a complete backup with products, settings and photos.",
        ),
    ]
    specs = italian_specs if language == "it" else english_specs
    missing = [str(spec.source) for spec in specs if not spec.source.is_file()]
    if missing:
        raise FileNotFoundError(
            "Missing final release screenshots:\n" + "\n".join(missing)
        )
    for spec in specs:
        _compose(background, spec).save(output / spec.filename, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--background", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--language", choices=("it", "en"), default="it")
    args = parser.parse_args()
    generate(args.background, args.output, args.root.resolve(), args.language)


if __name__ == "__main__":
    main()
