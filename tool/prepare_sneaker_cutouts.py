"""Prepare transparent Cloudinary derivatives; keep originals untouched.
Requires Pillow for alpha validation. No paid add-on is enabled by this script.
"""
import concurrent.futures
import io
import json
from pathlib import Path
import time
import urllib.error
import urllib.request
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CACHE = Path('/private/tmp/fashion-cutouts')
CACHE.mkdir(exist_ok=True)
TRANSFORM = 'e_background_removal/e_trim/f_png'


def prepare(url):
    if TRANSFORM in url:
        return url.replace(f'/image/upload/{TRANSFORM}/', '/image/upload/', 1), url
    derived = url.replace('/image/upload/', f'/image/upload/{TRANSFORM}/', 1)
    name = url.rsplit('/', 1)[-1].rsplit('.', 1)[0] + '-' + url.split('/')[-2] + '.png'
    target = CACHE / name
    if target.exists():
        content = target.read_bytes()
    else:
        for attempt in range(12):
            try:
                with urllib.request.urlopen(derived, timeout=60) as response:
                    content = response.read()
                break
            except urllib.error.HTTPError as error:
                if error.code not in (420, 423):
                    raise RuntimeError(f'{error.code}: {error.headers.get("X-Cld-Error")}') from error
                time.sleep(5)
        else:
            raise RuntimeError('Background removal is still pending; originals have been preserved.')
        target.write_bytes(content)
    image = Image.open(io.BytesIO(content))
    alpha = image.getchannel('A').getextrema() if image.mode == 'RGBA' else (255, 255)
    if image.mode != 'RGBA' or alpha[0] > 5 or alpha[1] < 200:
        raise ValueError(f'No valid transparent foreground: {name}')
    print('Prepared', name, image.size, flush=True)
    return url, derived


def main():
    path = ROOT / 'assets/catalog/sneakers.json'
    catalog = json.loads(path.read_text())
    urls = sorted({url for p in catalog['products'] for url in p['Images']})
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        replacements = dict(pool.map(prepare, urls))
    # Replace only exact image URLs, including brand/category thumbnails and variants.
    def replace(value):
        if isinstance(value, str):
            return replacements.get(value, value)
        if isinstance(value, list):
            return [replace(item) for item in value]
        if isinstance(value, dict):
            return {key: replace(item) for key, item in value.items()}
        return value
    catalog = replace(catalog)
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    (ROOT / 'tool/sneaker_cutouts.json').write_text(json.dumps(replacements, indent=2) + '\n')
    print('Prepared transparent images:', len(replacements), flush=True)


if __name__ == '__main__':
    main()
