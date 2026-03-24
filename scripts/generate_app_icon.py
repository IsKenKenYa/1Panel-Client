from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / 'assets' / 'branding' / 'app_icon_master.png'
PREVIEW = ROOT / 'assets' / 'branding' / 'app_icon_preview.png'

BG_TOP = (12, 24, 42)
BG_BOTTOM = (9, 88, 104)
PANEL = (245, 248, 252)
ACCENT = (104, 226, 197)
ACCENT_2 = (118, 196, 255)
SHADOW = (6, 15, 24, 140)


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def vertical_gradient(size: int) -> Image.Image:
    base = Image.new('RGBA', (size, size))
    pixels = base.load()
    for y in range(size):
        t = y / (size - 1)
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        for x in range(size):
            pixels[x, y] = (r, g, b, 255)
    return base


def make_master(size: int = 1024) -> Image.Image:
    image = vertical_gradient(size)
    image.putalpha(255)

    draw = ImageDraw.Draw(image)
    radius = int(size * 0.23)
    margin = int(size * 0.06)

    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (margin, margin + int(size * 0.02), size - margin, size - margin),
        radius=radius,
        fill=SHADOW,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(size * 0.025)))
    image.alpha_composite(shadow)

    card = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle(
        (margin, margin, size - margin, size - margin),
        radius=radius,
        fill=(16, 33, 52, 230),
        outline=(220, 236, 248, 36),
        width=max(2, size // 128),
    )
    image.alpha_composite(card)

    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (int(size * 0.16), int(size * 0.12), int(size * 0.84), int(size * 0.82)),
        fill=(90, 220, 200, 28),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(size * 0.08)))
    image.alpha_composite(glow)

    pillar_x0 = int(size * 0.27)
    pillar_x1 = int(size * 0.41)
    pillar_y0 = int(size * 0.24)
    pillar_y1 = int(size * 0.76)
    draw.rounded_rectangle(
        (pillar_x0, pillar_y0, pillar_x1, pillar_y1),
        radius=int(size * 0.08),
        fill=ACCENT,
    )
    draw.rounded_rectangle(
        (pillar_x0 + int(size * 0.015), pillar_y0 + int(size * 0.02), pillar_x1 - int(size * 0.03), pillar_y1 - int(size * 0.02)),
        radius=int(size * 0.065),
        fill=ACCENT_2,
    )

    tile_size = int(size * 0.16)
    gap = int(size * 0.035)
    start_x = int(size * 0.48)
    start_y = int(size * 0.31)
    tile_radius = int(size * 0.04)

    for row in range(2):
        for col in range(2):
            x0 = start_x + col * (tile_size + gap)
            y0 = start_y + row * (tile_size + gap)
            x1 = x0 + tile_size
            y1 = y0 + tile_size
            fill = PANEL
            if row == 0 and col == 1:
                fill = (200, 255, 240)
            draw.rounded_rectangle((x0, y0, x1, y1), radius=tile_radius, fill=fill)

    dot_r = int(size * 0.03)
    dot_cx = pillar_x0 + int(size * 0.02)
    dot_cy = int(size * 0.19)
    draw.ellipse((dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r), fill=PANEL)
    draw.line((dot_cx, dot_cy + dot_r, dot_cx, pillar_y0 - int(size * 0.015)), fill=PANEL, width=max(4, size // 96))

    shine = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    shine_draw.rounded_rectangle(
        (margin + int(size * 0.05), margin + int(size * 0.04), size - margin - int(size * 0.18), margin + int(size * 0.16)),
        radius=int(size * 0.08),
        fill=(255, 255, 255, 22),
    )
    shine = shine.filter(ImageFilter.GaussianBlur(int(size * 0.02)))
    image.alpha_composite(shine)

    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    mask = rounded_rect_mask(size, radius=int(size * 0.24))
    final.paste(image, (0, 0), mask)
    return final


def save_png(img: Image.Image, path: Path, size: int):
    out = img.resize((size, size), Image.Resampling.LANCZOS)
    out.save(path)


def main():
    master = make_master(1024)
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    master.save(MASTER)
    save_png(master, PREVIEW, 512)

    android = {
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    }
    ios = {
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
    }
    mac = {
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    }
    web = {
        'web/favicon.png': 32,
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
    }

    for mapping in (android, ios, mac, web):
        for rel, size in mapping.items():
            path = ROOT / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            save_png(master, path, size)

    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    ico = master.resize((256, 256), Image.Resampling.LANCZOS)
    ico.save(ROOT / 'windows/runner/resources/app_icon.ico', sizes=ico_sizes)

    print('generated icons at', MASTER)


if __name__ == '__main__':
    main()
