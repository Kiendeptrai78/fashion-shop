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

## Language, currency and local welcome flow

Customer screens default to Vietnamese. Settings → Language switches between
Vietnamese/VND and English/USD and persists the choice in the device-level
`app_preferences` GetStorage container. Shared `ShopText` labels follow Flutter's
inherited locale, including const widgets. Currency formatting is centralized in
`lib/utils/localization/shop_locale.dart`: 1 USD = 25,812 VND, a fixed project rate
rather than a live quote. Product/order prices remain USD in Firestore and local
cart data. VND display rounds to whole dong; Demo bank uses the same rate and rounding.
Existing shipping/tax calculations are unchanged. The storefront no longer calls
the legacy ZaloPay payment integration.

After verified login, users without `shopper_preferences_v1.completed` see the
welcome, optional age-group and category-interest steps. Categories come from the
catalog metadata. Preferences and completion/skip status stay in the existing
per-user local storage bucket; no age or interest data is uploaded. Settings →
Your preferences edits these choices. Clearing app data causes the flow to appear
again. Intro transitions respect the OS reduced-motion setting.

## Account screens and simulated checkout

The storefront offers Cash on delivery and Demo bank. Demo bank is an in-app
simulation, with no real bank account or transfer. Each per-user local benefits
record starts at VND 10,000,000; users can add another VND 10,000,000 for testing.
Balances, transaction history, redeemed coupons and checkout receipt IDs are kept
in `customer_benefits_demo_v1`. A stable checkout document ID prevents duplicate
Firestore orders on retry; only a successful order write consumes a coupon and
debits demo funds. Cancelling a saved demo order refunds its recorded local debit
once. Orders themselves remain in the user's Firestore Orders subcollection.

Welcome gifts: WELCOME10 (10%, maximum USD 10, minimum USD 50, 30 days) and SHIPNEW
(shipping fee, 14 days). One coupon per order. Holiday gifts are 15%, maximum USD
15, minimum USD 40, valid for 7 days. They are issued once per holiday/year when
the app is opened or the coupon wallet is refreshed during the validity window.
The store's promotional calendar includes Jan 1, Mar 8, Apr 30, May 1, Sep 2,
Nov 20, Dec 25, Tết, Hùng Kings Festival and Mid-autumn Festival. Lunar dates use
[vnlunar](https://pub.dev/packages/vnlunar) with UTC+7. These are demo offers and
local demo balances, rather than a server-enforced payment or promotion system.

My Addresses and My Orders read the signed-in user's existing records, support
refresh and render loading, empty and error states. Order actions target the
specific order ID and validate the saved status before changing it. The account
notification inbox shows current order updates and saves read status locally;
it does not claim to deliver push notifications. Privacy controls edit or clear
only age/interests and link to the existing account management screen. Cart and
Wishlist badges use red/white counts, hide zero and display 99+ above 99.

## Address map, activity badges and push setup

The address picker now refreshes its cached request after returning from Add
address. The add screen includes an interactive OpenStreetMap map, optional
latitude/longitude and attribution; it does not request GPS permission. Map tiles
use the app's user agent. OpenStreetMap's public tile policy applies; no offline
bulk downloading is implemented. Older addresses without coordinates still work.

The payment account UI uses normal balance/top-up/history labels; test-fund
information remains in Account information and the top-up confirmation. It still
uses the existing local test balance rather than a real bank/payment provider.

Per-user Orders/Addresses/Notifications streams drive account counters. Order
status tabs show totals with white selected labels; new coupon badges clear when
the coupon wallet is viewed. Notifications can be marked read and route to the
matching saved order/product. No age information is uploaded. When push is enabled,
only device token, followed category IDs and language are registered for targeting.

Actual Firebase push is deliberately gated behind `PUSH_BACKEND_READY=true` until
private Firestore rules and server/APNs credentials are configured. See
[server/push/README.md](server/push/README.md) for the ready-to-run Node worker and
setup steps without deploying Cloud Functions or enabling Firebase billing.
No Admin credential, APNs key, live worker, deployed rules or real push delivery
has been fabricated by this implementation.


## Branded startup and customer reviews

Native iOS/Android launch resources and the Flutter splash use the same forest
background. The Flutter intro respects reduced motion and adds no fixed startup
wait. Launch resources are maintained directly; running a splash generator will
overwrite this branding.

Product detail links to recent product reviews (up to 50), with a summary,
star filters, empty/error states and a review editor. Reviews are stored at
`Products/{productId}/Reviews/{uid}`. The client checks for a received order
containing the product before writing. Production release must also enforce
purchase eligibility and review field/ownership validation in trusted server
code or Firestore rules; the client check alone is not an authorization boundary.
No review rules were deployed and no sample reviews were posted.
