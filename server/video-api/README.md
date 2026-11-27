# Pixabay video search

Worker `velora-video-api` (Cloudflare Free), endpoint `/videos?q=sneakers&page=1`.
Public read-only collections are available at `/collections/{running|training|basketball|trail|lifestyle}?page=1`.
The entertainment feed also uses `/collections/{animals|travel|nature|sports|city}?page=1`.
`/collections/animation` reads a fixed catalog of four Creative Commons open
films from the Internet Archive metadata API; it needs no API key. Their
original AAC soundtracks were checked for an audible signal. The mobile source
panel displays the film title, copyright holder, original page and license.
Each topic returns up to ten clips, interleaved in the mobile feed with suggested shoes.
Mobile-sized originals are preferred. Bounded MP4 header probes exclude known
unsupported AVC profiles (High 10 / 4:2:2 / 4:4:4), then the result is cached for
24 hours. If a format probe is unavailable, the catalog stays available.
Their queries are fixed on the server, with at most 3 pages of 10 results and a
24-hour cache. Arbitrary public searches and additional pages are rejected.
Only Firebase ID tokens for the existing Admin's pinned `ADMIN_UID` and
`AdminConfig.adminEmail` can search. The worker validates RS256 signatures against
Google's public keys, project, issuer, expiry, UID and email. Email verification
is not required for this existing account: another account with the same email
still fails the UID check. It never accepts a caller-provided UID/email as authorization.

`PIXABAY_API_KEY` is a Cloudflare Secret. No key in Dart, source control, request
parameters from the client, or API responses. Do not log upstream request URLs:
Pixabay requires its key as a query parameter.

Each human search returns 10 video results, cached for 24 hours as required by
Pixabay. Admin selects a video and a product; the video URL and real provider,
author and source-page link are stored in the product's `VideoSources` field.
Mobile reads the explicit `Videos` list and source metadata from Firestore.
There is no automatic stock-video assignment pretending to be a customer review.

Run tests: `node --test server/video-api/*.test.mjs`.
Deploy from this directory using the installed Wrangler CLI:
`../push/cloudflare/node_modules/.bin/wrangler deploy --config wrangler.jsonc`.

Pixabay permits embedding videos directly; search image thumbnails are temporary
search previews. API limits currently allow up to 500 accessible results per
query, so the picker stops at 50 pages of 10. Use a different search term to
explore more footage; do not claim an unlimited library from one query.

Audio is source-dependent. The app cannot restore audio absent from an MP4.
An AAC track may contain digital silence. `hasAudio` describes the track;
`audiblePreview` is set only for explicitly measured original files in
`audio-preview-checks.mjs` (first and midpoint five-second samples), or the
verified open-film catalog. The app shuffles each newly loaded feed, removes
duplicates, and prioritizes verified audible originals rather than empty AAC
tracks. It reads up to three cached pages per Pixabay topic.
Mobile and Admin use an accessible seek slider, show elapsed/total time, and
preserve the user's pause state after seeking. Video playback uses the native
media audio session, with an explicit mute/unmute control.

The 30 legacy curated clips in `curated-videos.json` have an original VELORA instrumental
mixed into the MP4 (AAC), then are hosted on Cloudinary. Each of the five shoe
categories has six clips. `curated-video-assignments.json` records the product
links; the app reads these assignments from Firestore. Original Pixabay authors,
source pages and original video URLs are preserved; the footage remains inspiration,
not an endorsement or customer review. Existing product videos are retained.
`scripts/create_soundtracks.py OUTPUT_DIR` reproduces the five synthesized loops
without third-party samples or recordings. The 30 published URLs were checked
with ffprobe for AAC audio after upload.
Mobile now selects `originalUrl` for these legacy mixes and skips a mix if the
original URL is missing. No background music is added to entertainment videos;
sound comes only from the original MP4 and can be muted by the viewer.

Official docs: https://pixabay.com/api/docs/
