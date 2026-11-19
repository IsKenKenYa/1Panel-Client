import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / 'assets/branding'
SRGB = (BRANDING / 'sources/sRGB.icc').read_bytes()


def load_mark(name):
    with Image.open(BRANDING / 'sources' / f'{name}.png') as source:
        image = source.convert('RGBA')
    alpha = image.getchannel('A')
    if image.size != (2880, 2880) or alpha.getextrema() != (0, 255):
        raise ValueError(f'需要 2880×2880 透明原图：{name}')
    # 使用有效 Alpha 范围消除原图留白，保留边缘的抗锯齿像素。
    bounds = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bounds is None:
        raise ValueError(f'图形内容为空：{name}')
    return image.crop(bounds)


def foreground(mark, size, extent):
    image = Image.new('RGBA', (size, size))
    fitted = ImageOps.contain(mark, (round(size * extent), round(size * extent)), Image.Resampling.LANCZOS)
    image.alpha_composite(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2))
    return image


def opaque_icon(mark, size, extent=0.68, background='white'):
    image = Image.new('RGBA', (size, size), background)
    image.alpha_composite(foreground(mark, size, extent))
    return image.convert('RGB')


def desktop_card(mark, size):
    # macOS 传统 AppIcon 保留透明边距，卡片与 Dock 中的其他图标大小接近。
    canvas = Image.new('RGBA', (1024, 1024))
    mask = Image.new('L', canvas.size)
    ImageDraw.Draw(mask).rounded_rectangle((100, 100, 924, 924), radius=184, fill=255)
    shadow = Image.new('RGBA', canvas.size, (20, 45, 65, 42))
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(16)).point(lambda value: round(value * 0.16)))
    canvas.alpha_composite(shadow, (0, 12))
    card = Image.new('RGBA', canvas.size, 'white')
    card.putalpha(mask)
    card.alpha_composite(foreground(mark, 1024, 0.59))
    canvas.alpha_composite(card)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def save_png(image, relative):
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, icc_profile=SRGB, optimize=True)


def apple_icons(flat, gradient, glass):
    for platform in ['ios', 'macos']:
        folder = Path(platform) / 'Runner/Assets.xcassets/AppIcon.appiconset'
        catalog = json.loads((ROOT / folder / 'Contents.json').read_text())
        for entry in catalog['images']:
            size = round(float(entry['size'].split('x')[0]) * float(entry.get('scale', '1x')[:-1]))
            mark = glass if size >= 60 else flat
            if platform == 'macos':
                image = desktop_card(mark, size)
            elif entry.get('appearances', [{}])[0].get('value') == 'tinted':
                image = ImageOps.grayscale(opaque_icon(flat, size)).convert('RGB')
            else:
                image = opaque_icon(mark, size)
            save_png(image, folder / entry['filename'])
    save_png(foreground(flat, 1024, 0.68),
             'assets/branding/1Panel-Client-Apple.icon/Assets/app_icon_foreground.png')


def android_icons(flat):
    folder = Path('android/app/src/main/res')
    for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
        target = folder / f'mipmap-{density}'
        save_png(opaque_icon(flat, round(48 * scale)), target / 'ic_launcher.png')
        # 图形宽度为 48dp，全部内容位于 66dp 安全圆内。
        layer = foreground(flat, round(108 * scale), 48 / 108)
        save_png(layer, target / 'ic_launcher_foreground.png')
        mono = Image.new('RGBA', layer.size, 'black')
        mono.putalpha(layer.getchannel('A'))
        save_png(mono, target / 'ic_launcher_monochrome.png')
    save_png(opaque_icon(flat, 512), 'assets/branding/android_store_icon.png')


def desktop_web_icons(flat, gradient, glass):
    windows = foreground(gradient, 256, 0.84)
    windows.save(ROOT / 'windows/runner/resources/app_icon.ico',
                 sizes=[(n, n) for n in [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]])
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        mark = flat if size <= 32 else gradient
        save_png(foreground(mark, size, 0.84),
                 f'linux/runner/resources/hicolor/{size}x{size}/apps/com.iskenkenya.onepanel.png')
    for size in [192, 512]:
        save_png(opaque_icon(gradient, size), f'web/icons/Icon-{size}.png')
        save_png(opaque_icon(gradient, size, 0.54), f'web/icons/Icon-maskable-{size}.png')
    save_png(foreground(flat, 32, 0.88), 'web/favicon.png')
    save_png(opaque_icon(glass, 180), 'web/icons/apple-touch-icon.png')
    for relative in ['ohos/AppScope/resources/base/media/app_icon.png',
                     'ohos/entry/src/main/resources/base/media/icon.png']:
        save_png(opaque_icon(glass, 1024, 0.54), relative)


def preview(flat, gradient, glass):
    sheet = Image.new('RGB', (1200, 650), '#EEF2F6')
    draw = ImageDraw.Draw(sheet)
    samples = [('iOS / iPadOS', opaque_icon(glass, 256)),
               ('macOS', desktop_card(glass, 256)),
               ('Android', opaque_icon(flat, 256)),
               ('Windows', foreground(gradient, 256, 0.84)),
               ('Linux', foreground(gradient, 256, 0.84)),
               ('HarmonyOS', opaque_icon(glass, 256, 0.54))]
    for index, (name, image) in enumerate(samples):
        x = 20 + index % 3 * 400
        y = 10 + index // 3 * 320
        sheet.paste(image, (x + 62, y), image if image.mode == 'RGBA' else None)
        draw.text((x + 120, y + 270), name, fill='#17394F')
    save_png(sheet, 'assets/branding/platform_icons_preview.png')


def main():
    flat, gradient, glass = [load_mark(name) for name in ['flat', 'gradient', 'glass']]
    save_png(opaque_icon(gradient, 1024), 'assets/branding/app_icon_master.png')
    save_png(opaque_icon(gradient, 512), 'assets/branding/app_icon_preview.png')
    apple_icons(flat, gradient, glass)
    android_icons(flat)
    desktop_web_icons(flat, gradient, glass)
    preview(flat, gradient, glass)
    print('已使用选定的蓝青色 1P 原图生成全部平台图标')


if __name__ == '__main__':
    main()
