# fashion_business_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Image uploads (Cloudinary)

New images use Cloudinary; product records and authentication still use Firebase.
Create a Cloudinary Free account, then create an **Unsigned** upload preset under
Settings → Upload → Upload presets. Restrict it to image formats and a suitable
maximum file size. Unsigned presets allow uploads by clients that know the preset;
use backend-signed uploads before exposing unrestricted production uploads.
Never put a Cloudinary API secret in the Flutter app.

Copy `cloudinary.config.example.json` to `cloudinary.config.json` and fill in the
Cloud name and preset name. Run:

```sh
flutter run --dart-define-from-file=cloudinary.config.json
```

A full restart with these arguments is required after changing configuration.
Existing Firebase Storage URLs are preserved. Blocked Firebase files cannot be
migrated by changing the upload service: restore access to export them, or upload
original images again through the admin screens and save the updated records.

## Sneaker catalog

`assets/catalog/sneakers.json` contains 24 sample sneaker models from six brands,
72 Cloudinary photos, five categories, and 504 size/color variants (EU 38–44).
Prices are demo USD values and inventory is synthetic. Each product's stock is
exactly the sum of its variant stocks. Photo labels/provenance and SHA-256 hashes
are in `tool/sneaker_sources.json`; the source is the public
[ipogorelov/sneakers dataset](https://huggingface.co/datasets/ipogorelov/sneakers).
The dataset card declares MIT and describes images collected from Bing; these
are sample reference photos, not verified retail SKUs or a supplier stock feed.

Import the catalog once with the existing authenticated Firebase session:

```sh
flutter run --dart-define-from-file=cloudinary.config.json --dart-define=IMPORT_SNEAKER_CATALOG=true
```

The importer creates new `sneaker-` documents and category/brand associations in
Firestore. A `CatalogImports/sneakers-v1` marker prevents repeated imports and
inventory resets. It never deletes existing products. Subsequent launches only
need `--dart-define-from-file=cloudinary.config.json`. Home reads the imported
catalog from Firestore and supports search, brand filters and category filters.

To reproduce Cloudinary uploads, install `pyarrow` in a Python environment and run:

```sh
python tool/upload_sneaker_catalog.py --config cloudinary.config.json
```

The uploader caches source parquet files and upload responses in a temporary
directory. It verifies each source image hash before uploading and uses stable
public IDs so a retry does not create duplicate assets.

## Catalog pagination and transparent photos

The storefront requests 10 products per page using Firestore document-ID cursors.
One extra document is fetched as a next-page probe; there is no fixed page cap and
only the current page's products are kept in the catalog controller. Brand and
category routes reuse the same paginated screen.

`BrowseKeys` is a Firestore array index containing brand/category combinations and
normalized word/name prefixes. Searches run on the server across the full catalog,
including products outside the current page. Search is case-insensitive prefix
matching (model, brand, category or individual words), not arbitrary substring or
fuzzy matching. New admin product writes generate these keys with `ProductModel`.
Only brand/category metadata is loaded separately; the storefront no longer starts
the admin controller's full-product subscription.

`tool/prepare_sneaker_cutouts.py` requests Cloudinary background-removal PNG
versions, validates their alpha channels and leaves the original uploads intact.
It records the original/derived URL map in `tool/sneaker_cutouts.json`. The first
launch with `IMPORT_SNEAKER_CATALOG=true` upgrades the existing catalog's photos and
search keys once (`CatalogImports/sneakers-presentation-v2`), without resetting
product prices, variant inventory or other edits.

To regenerate the transparent-photo manifest after rerunning the uploader:

```sh
python tool/prepare_sneaker_cutouts.py
```

This requires Pillow and uses Cloudinary transformation quota. It does not enable
paid add-ons or upgrade the account. A failed transformation leaves the seed
manifest unchanged so the app never switches to an unprepared image URL.

## Storefront campaigns

`assets/catalog/campaigns.json` contains five campaigns, including three silent
nine-second motion lookbooks made from the catalog's shoe cutouts and two existing
banner artworks. Media is hosted on Cloudinary. Run once with
`--dart-define=IMPORT_SNEAKER_CATALOG=true` to add these records to `Banners`;
`CatalogImports/sneaker-campaigns-v1` prevents repeated imports. Existing banners
are preserved. Home reads active banners from Firestore, sorted by `SortOrder`.

Optional banner fields: `Title`, `Subtitle`, `VideoUrl`, `CategoryId`, `BrandId`,
and `SortOrder`. Old image-only records remain supported. Videos play muted only
for the current visible slide, pause in the background, respect reduced motion,
and show a poster if playback fails. Campaign links open filtered, paginated
collections. Promotions are hidden during search/filtering and after page one.
