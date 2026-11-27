import test from 'node:test';
import assert from 'node:assert/strict';
import worker, {isAdmin, normalizeVideo, avcProfile, mp4HasAudio} from './worker.mjs';
import {loadOpenMovies, openMovies} from './open-movies.mjs';

const env = {FIREBASE_PROJECT_ID: 'demo', ADMIN_EMAIL: 'admin@example.com', ADMIN_UID: 'admin', PIXABAY_API_KEY: 'private-key'};
test('open films keep genuine source, attribution and license without a Pixabay key', async () => {
  const movies = await loadOpenMovies(async url => {
    const movie = openMovies.find(movie => url.endsWith(`/${movie.id}`));
    return Response.json({files: [{name: movie.file}]});
  });
  assert.equal(movies.length, 4);
  for (const movie of movies) {
    assert.equal(movie.audiblePreview, true);
    assert(movie.author.includes('Blender Foundation'));
    assert(movie.licenseUrl.startsWith('https://creativecommons.org/licenses/by/'));
    assert(movie.url.startsWith('https://archive.org/download/'));
  }
  const response = await worker.fetch(new Request('https://api.example/collections/animation?page=2'), {}, {});
  assert.equal(response.status, 200);
  assert.equal((await response.json()).hasMore, false);
});
test('MP4 audio detection reads a sound handler instead of assuming volume implies sound', () => {
  const header = Uint8Array.from([0, 0, 0, 24, 0x68, 0x64, 0x6c, 0x72,
    0, 0, 0, 0, 0, 0, 0, 0, 0x73, 0x6f, 0x75, 0x6e]);
  assert.equal(mp4HasAudio(header), true);
  header[16] = 0x76;
  assert.equal(mp4HasAudio(header), false);
});
test('MP4 profile parser distinguishes High 10 from ordinary High AVC', () => {
  const header = Uint8Array.from([0, 0, 0, 16, 0x61, 0x76, 0x63, 0x43, 1, 110, 0, 40, 0]);
  assert.equal(avcProfile(header), 110);
  header[9] = 100;
  assert.equal(avcProfile(header), 100);
  assert.equal(avcProfile(new Uint8Array(20)), null);
});
const pair = await crypto.subtle.generateKey({name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048,
  publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256'}, true, ['sign', 'verify']);
const jwk = {...await crypto.subtle.exportKey('jwk', pair.publicKey), kid: 'test'};
const b64 = value => Buffer.from(typeof value === 'string' ? value : new Uint8Array(value)).toString('base64url');
async function token(extra = {}) {
  const now = Math.floor(Date.now() / 1000);
  const claims = {aud: 'demo', iss: 'https://securetoken.google.com/demo', sub: 'admin',
    email: 'admin@example.com', email_verified: true, iat: now, exp: now + 3600, ...extra};
  const value = `${b64(JSON.stringify({alg: 'RS256', kid: 'test'}))}.${b64(JSON.stringify(claims))}`;
  return `${value}.${b64(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', pair.privateKey, new TextEncoder().encode(value)))}`;
}
const hit = {id: 4, user: 'RealCreator', pageURL: 'https://pixabay.com/videos/id-4/', tags: 'running',
  duration: 12, videos: {medium: {url: 'https://cdn.pixabay.com/video/real.mp4', width: 720, height: 1280}}};

test('verified Firebase admin signatures are accepted; forged, expired and customer tokens are rejected', async () => {
  const fetcher = async () => Response.json({keys: [jwk]});
  assert.equal(await isAdmin(await token(), env, fetcher), true);
  assert.equal(await isAdmin(await token({email_verified: false}), env, fetcher), true);
  assert.equal(await isAdmin(await token(), {...env, ADMIN_UID: undefined}, fetcher), false);
  for (const claims of [{email: 'customer@example.com'}, {sub: 'different-user'}, {aud: 'other'},
    {exp: 1}, {exp: undefined}]) assert.equal(await isAdmin(await token(claims), env, fetcher), false);
  const valid = await token();
  assert.equal(await isAdmin(`${valid.slice(0, -10)}AAAAAAAAAA`, env, fetcher), false);
});

test('API keeps real creator/source metadata and rejects non-Pixabay URLs', () => {
  const video = normalizeVideo(hit);
  assert.equal(video.author, 'RealCreator');
  assert.equal(video.provider, 'Pixabay');
  assert.equal(video.sourceUrl, hit.pageURL);
  assert.equal(normalizeVideo({...hit, pageURL: 'https://other.com/'}), null);
});

test('mobile feed prefers HD files over a 1440p medium rendition', () => {
  const small = {...hit.videos.medium, url: 'https://cdn.pixabay.com/video/hd.mp4', width: 1280, height: 720};
  const video = normalizeVideo({...hit, videos: {small,
    medium: {...small, url: 'https://cdn.pixabay.com/video/large.mp4', width: 2560, height: 1440}}});
  assert.equal(video.url, small.url);
});

test('public requests cannot consume the API key', async () => {
  const response = await worker.fetch(new Request('https://api.example/videos?q=shoes'), env, {});
  assert.equal(response.status, 403);
  assert(!JSON.stringify(await response.json()).includes('private-key'));
});

test('public collections reject unknown slugs and pages outside their fixed range', async () => {
  for (const slug of ['custom-search', 'constructor', 'toString']) {
    const response = await worker.fetch(new Request(`https://api.example/collections/${slug}`), env, {});
    assert.equal(response.status, 404);
  }
  for (const page of ['0', '4', '99', 'NaN']) {
    const response = await worker.fetch(new Request(`https://api.example/collections/running?page=${page}`), env, {});
    assert.equal(response.status, 400);
  }
});

test('search uses ten items per page and caches responses for 24 hours without leaking the key', async () => {
  const originalFetch = globalThis.fetch, originalCaches = globalThis.caches;
  const saved = new Map(), upstream = [];
  globalThis.caches = {default: {
    match: async request => saved.get(request.url)?.clone(),
    put: async (request, response) => { saved.set(request.url, response); },
  }};
  globalThis.fetch = async url => {
    if (new URL(url).hostname === 'cdn.pixabay.com') {
      const profile = new URL(url).pathname.includes('high10') ? 110 : 100;
      return new Response(Uint8Array.from([0, 0, 0, 16, 0x61, 0x76, 0x63, 0x43, 1, profile, 0, 40, 0]), {status: 206});
    }
    upstream.push(new URL(url));return Response.json({hits: [hit,
      {...hit, id: 88, videos: {medium: {...hit.videos.medium,
        url: 'https://cdn.pixabay.com/high10.mp4'}}}], totalHits: 31});
  };
  const pending = [], ctx = {waitUntil: promise => pending.push(promise)};
  try {
    const auth = await token();
    const request = () => new Request('https://api.example/videos?q=running&page=2',
      {headers: {Authorization: `Bearer ${auth}`, Origin: 'https://fashion-business-app.web.app'}});
    const response = await worker.fetch(request(), env, ctx);
    const data = await response.json();
    assert.equal(data.videos.length, 1);
    assert.equal(data.videos[0].id, String(hit.id));
    await Promise.all(pending);
    assert.equal(data.hasMore, true);
    assert.equal(upstream[0].searchParams.get('per_page'), '10');
    assert.equal(upstream[0].searchParams.get('safesearch'), 'true');
    assert.equal([...saved.values()][0].headers.get('Cache-Control'), 'public,max-age=86400');
    assert(!JSON.stringify(data).includes('private-key'));
    assert.equal((await worker.fetch(request(), env, ctx)).status, 200);
    assert.equal(upstream.length, 1);
    const collection = await worker.fetch(new Request('https://api.example/collections/basketball?q=arbitrary'), env, ctx);
    assert.equal(collection.status, 200);
    assert.equal(upstream[1].searchParams.get('q'), 'basketball');
    assert.equal(upstream[1].searchParams.get('per_page'), '10');
    const lastCollectionPage = await worker.fetch(new Request('https://api.example/collections/basketball?page=3'), env, ctx);
    assert.equal((await lastCollectionPage.json()).hasMore, false);
    await Promise.all(pending);
    const adminPage = await worker.fetch(new Request('https://api.example/videos?q=basketball&page=3',
      {headers: {Authorization: `Bearer ${auth}`}}), env, ctx);
    assert.equal((await adminPage.json()).hasMore, true);
    const cachedCollectionPage = await worker.fetch(new Request('https://api.example/collections/basketball?page=3'), env, ctx);
    assert.equal((await cachedCollectionPage.json()).hasMore, false);
  } finally { globalThis.fetch = originalFetch; globalThis.caches = originalCaches; }
});
