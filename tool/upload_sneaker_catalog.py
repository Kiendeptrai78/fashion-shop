"""Upload the curated sneaker photos and build the Firestore seed manifest.

Requires pyarrow only when downloading the source parquet files.
Run: python tool/upload_sneaker_catalog.py --config cloudinary.config.json
"""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
CATALOG_ID = 'sneakers-v1'


def slug(value):
    return re.sub(r'[^a-z0-9]+', '-', value.lower()).strip('-')


def upload(config, product, photo, cache):
    import pyarrow.parquet as pq
    row = photo['sourceRow']
    batch, index = divmod(row, 1000)
    filename = f'dataset_batch_{batch + 1:02}.parquet'
    # Downloads are prepared once before parallel uploads.
    table = pq.read_table(cache / filename)
    content = table.slice(index, 1).to_pylist()[0]['image']
    if hashlib.sha256(content).hexdigest() != photo['sha256']:
        raise ValueError(f'Source image changed: {row}')
    public_id = f"{CATALOG_ID}/{product['id']}/{slug(photo['color'])}"
    result_file = cache / (slug(public_id) + '.upload.json')
    if result_file.exists():
        result = json.loads(result_file.read_text())
        if result.get('cloud') == config['CLOUDINARY_CLOUD_NAME']:
            return product['id'], photo['color'], result['response']
    boundary = 'catalog-' + uuid.uuid4().hex
    fields = {
        'upload_preset': config['CLOUDINARY_UPLOAD_PRESET'],
        'public_id': public_id,
        'asset_folder': f"SneakerCatalog/{product['brand']}/{product['category']}/{product['model']}",
        'tags': f"{CATALOG_ID},{slug(product['brand'])},{slug(product['category'])}",
    }
    parts = []
    for name, value in fields.items():
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
    parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{slug(public_id)}.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'.encode())
    parts.extend([content, f'\r\n--{boundary}--\r\n'.encode()])
    url = f"https://api.cloudinary.com/v1_1/{config['CLOUDINARY_CLOUD_NAME']}/image/upload"
    request = urllib.request.Request(url, data=b''.join(parts), headers={
        'Content-Type': f'multipart/form-data; boundary={boundary}',
    })
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(error.read().decode()) from error
    if not result.get('secure_url', '').startswith('https://'):
        raise ValueError('Upload did not return a secure URL')
    result_file.write_text(json.dumps({'cloud': config['CLOUDINARY_CLOUD_NAME'], 'response': result}))
    print('Uploaded', public_id, flush=True)
    return product['id'], photo['color'], result


def build_catalog(products, uploads):
    brands = []
    categories = []
    records = []
    for i, p in enumerate(products):
        brand_id = 'sneaker-brand-' + slug(p['brand'])
        category_id = 'sneaker-category-' + slug(p['category'])
        photos = [uploads[(p['id'], image['color'])]['secure_url'] for image in p['images']]
        brand = next((b for b in brands if b['Id'] == brand_id), None)
        if brand is None:
            brand = {'Id': brand_id, 'Name': p['brand'], 'Image': photos[0],
                     'ProductsCount': 0, 'IsFeatured': True, 'CatalogId': CATALOG_ID}
            brands.append(brand)
        brand['ProductsCount'] += 1
        if not any(c['Id'] == category_id for c in categories):
            categories.append({'Id': category_id, 'Name': p['category'], 'Image': photos[0],
                               'ParentId': '', 'IsFeatured': True, 'CatalogId': CATALOG_ID})
        sale = round(p['price'] * 0.85, 2) if i % 4 == 0 else 0
        variations = []
        for color_index, photo in enumerate(p['images']):
            for size in range(38, 45):
                stock = 2 + (i * 7 + color_index * 5 + size) % 11
                variations.append({
                    'Id': f"{p['id']}-{slug(photo['color'])}-{size}",
                    'Image': photos[color_index], 'Price': p['price'], 'SalePrice': sale,
                    'Stock': stock, 'Description': f"{p['brand']} {p['model']} · EU {size} · {photo['color']}",
                    'AttributeValues': {'Size': str(size), 'Color': photo['color']},
                })
        records.append({
            'Id': p['id'], 'Title': p['model'], 'Stock': sum(v['Stock'] for v in variations),
            'Price': p['price'], 'SalePrice': sale, 'Thumbnail': photos[0], 'Images': photos,
            'IsFeatured': True, 'ProductType': 'ProductType.variable',
            'CategoryId': category_id, 'CategoryName': p['category'], 'CatalogId': CATALOG_ID,
            'Brand': {'Id': brand_id, 'Name': p['brand'], 'Image': photos[0],
                      'ProductsCount': 4, 'IsFeatured': True},
            'Description': f"{p['brand']} {p['model']} from the {p['category'].lower()} collection. "
                           'Choose from three colorways and EU sizes 38–44. '
                           'Sample catalog: prices and stock are demonstration values.',
            'ProductAttributes': [{'Name': 'Size', 'Values': [str(s) for s in range(38, 45)]},
                                  {'Name': 'Color', 'Values': [p['color'] for p in p['images']]}],
            'ProductVariations': variations,
        })
    return {'catalogId': CATALOG_ID, 'currency': 'USD', 'demoInventory': True,
            'source': 'https://huggingface.co/datasets/ipogorelov/sneakers',
            'imageCount': len(uploads), 'brands': brands, 'categories': categories, 'products': records}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='cloudinary.config.json')
    parser.add_argument('--cache', default='/private/tmp/fashion-sneakers')
    args = parser.parse_args()
    config = json.loads(Path(args.config).read_text())
    products = json.loads((ROOT / 'tool/sneaker_sources.json').read_text())['products']
    cache = Path(args.cache)
    cache.mkdir(parents=True, exist_ok=True)
    batches = {photo['sourceRow'] // 1000 + 1 for p in products for photo in p['images']}
    for batch in sorted(batches):
        filename = f'dataset_batch_{batch:02}.parquet'
        if not (cache / filename).exists():
            urllib.request.urlretrieve(
                'https://huggingface.co/datasets/ipogorelov/sneakers/resolve/main/' + filename,
                cache / filename)
    uploads = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        jobs = [pool.submit(upload, config, p, photo, cache) for p in products for photo in p['images']]
        for job in concurrent.futures.as_completed(jobs):
            product_id, color, result = job.result()
            uploads[(product_id, color)] = result
    catalog = build_catalog(products, uploads)
    output = ROOT / 'assets/catalog/sneakers.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    print(f"Complete: {len(uploads)} photos, {len(catalog['products'])} products, "
          f"{len(catalog['brands'])} brands, {len(catalog['categories'])} categories.", flush=True)


if __name__ == '__main__':
    main()
