import configparser
import json
import math
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / 'android/app/src/main/res'


def check_png(path, size, opaque=False, profile=True):
    with Image.open(path) as image:
        image.load()
        assert image.format == 'PNG', path
        assert image.size == (size, size), (path, image.size, size)
        if profile:
            assert image.info.get('icc_profile'), f'缺少 sRGB 色彩配置：{path}'
        if opaque:
            assert image.mode == 'RGB', f'需要无 Alpha 通道的 PNG：{path}'
        return image.convert('RGBA')


def check_apple(platform):
    folder = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    contents = json.loads((folder / 'Contents.json').read_text())
    for entry in contents['images']:
        size = round(float(entry['size'].split('x')[0]) * float(entry.get('scale', '1x')[:-1]))
        image = check_png(folder / entry['filename'], size, opaque=platform == 'ios')
        if platform == 'macos':
            assert image.getpixel((0, 0))[3] == 0, entry
            assert image.getchannel('A').getextrema() == (0, 255), entry


def check_safe_circle(image, radius):
    alpha = image.getchannel('A').point(lambda value: 255 if value > 8 else 0)
    bounds = alpha.getbbox()
    assert bounds is not None
    for y in range(bounds[1], bounds[3]):
        for x in range(bounds[0], bounds[2]):
            if alpha.getpixel((x, y)):
                assert math.hypot(x + 0.5 - image.width / 2, y + 0.5 - image.height / 2) <= radius, (x, y)


def check_android():
    namespace = '{http://schemas.android.com/apk/res/android}'
    for suffix, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
        folder = ANDROID / f'mipmap-{suffix}'
        check_png(folder / 'ic_launcher.png', round(48 * scale), opaque=True)
        foreground = check_png(folder / 'ic_launcher_foreground.png', round(108 * scale))
        mono = check_png(folder / 'ic_launcher_monochrome.png', round(108 * scale))
        check_safe_circle(foreground, 33 * scale)
        check_safe_circle(mono, 33 * scale)
        assert mono.getchannel('A').getbbox() == foreground.getchannel('A').getbbox()
        assert ImageChops.difference(mono.getchannel('A'), foreground.getchannel('A')).getbbox() is None
    for api in [26, 33]:
        config = ET.parse(ANDROID / f'mipmap-anydpi-v{api}/ic_launcher.xml').getroot()
        assert config.tag == 'adaptive-icon'
        assert config.find('foreground').get(namespace + 'drawable') == '@mipmap/ic_launcher_foreground'
        assert config.find('background').get(namespace + 'drawable') == '@color/ic_launcher_background'
        if api == 33:
            assert config.find('monochrome').get(namespace + 'drawable') == '@mipmap/ic_launcher_monochrome'


def check_windows_linux_web():
    with Image.open(ROOT / 'windows/runner/resources/app_icon.ico') as image:
        assert image.format == 'ICO'
        assert image.ico.sizes() == {(n, n) for n in [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]}
        for size in image.ico.sizes():
            frame = image.ico.getimage(size).convert('RGBA')
            assert frame.getchannel('A').getextrema() == (0, 255)
    desktop = configparser.ConfigParser(interpolation=None)
    desktop.read(ROOT / 'linux/packaging/com.iskenkenya.onepanel.desktop')
    assert desktop['Desktop Entry']['Icon'] == 'com.iskenkenya.onepanel'
    theme = configparser.ConfigParser(interpolation=None)
    theme.read(ROOT / 'linux/runner/resources/hicolor/index.theme')
    for directory in theme['Icon Theme']['Directories'].split(','):
        assert theme.has_section(directory)
        assert (ROOT / 'linux/runner/resources/hicolor' / directory / 'com.iskenkenya.onepanel.png').is_file()
    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        check_png(ROOT / f'linux/runner/resources/hicolor/{size}x{size}/apps/com.iskenkenya.onepanel.png', size)
    manifest = json.loads((ROOT / 'web/manifest.json').read_text())
    for icon in manifest['icons']:
        size = int(icon['sizes'].split('x')[0])
        check_png(ROOT / 'web' / icon['src'], size, opaque=True)
        if icon.get('purpose') == 'maskable':
            image = Image.open(ROOT / 'web' / icon['src']).convert('RGB')
            delta = ImageChops.difference(image, Image.new('RGB', image.size, 'white'))
            mask = Image.new('RGBA', image.size)
            mask.putalpha(delta.convert('L').point(lambda value: 255 if value > 8 else 0))
            check_safe_circle(mask, size * 0.4)
    check_png(ROOT / 'web/icons/apple-touch-icon.png', 180, opaque=True)
    check_png(ROOT / 'web/favicon.png', 32)


def main():
    check_apple('ios')
    check_apple('macos')
    check_android()
    check_windows_linux_web()
    for relative in ['ohos/AppScope/resources/base/media/app_icon.png',
                     'ohos/entry/src/main/resources/base/media/icon.png']:
        check_png(ROOT / relative, 1024, opaque=True)
    for name in ['flat', 'gradient', 'glass']:
        source = check_png(ROOT / f'assets/branding/sources/{name}.png', 2880, profile=False)
        assert source.getchannel('A').getextrema() == (0, 255)
        assert source.getchannel('A').getbbox() != (0, 0, 2880, 2880)
    composer = ROOT / 'assets/branding/1Panel-Client-Apple.icon'
    config = json.loads((composer / 'icon.json').read_text())
    for group in config['groups']:
        for layer in group['layers']:
            image = check_png(composer / 'Assets' / layer['image-name'], 1024)
            assert image.getchannel('A').getextrema() == (0, 255)
    host = ROOT / 'windows/runner/native_host/OnePanelNativeHost'
    config = ET.parse(host / 'OnePanelNativeHost.csproj').getroot()
    icon = config.find('PropertyGroup/ApplicationIcon').text
    assert (host / icon.replace('\\', '/')).resolve().is_file()
    print('全部平台图标尺寸、色彩配置、透明度、资源目录及安全范围检查通过')


if __name__ == '__main__':
    main()
