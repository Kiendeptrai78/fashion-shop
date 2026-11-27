import {audioPreviewPeaks} from './audio-preview-checks.mjs';
import {loadOpenMovies} from './open-movies.mjs';
let keys;
// Public inspiration collections are bounded; arbitrary searches remain Admin-only.
const collections = {running: 'running sport', training: 'fitness workout',
  basketball: 'basketball', trail: 'hiking', lifestyle: 'skateboard sneakers',
  animals: 'cute animals', travel: 'travel', nature: 'nature waterfall',
  sports: 'sport action', city: 'city lifestyle'};
const decode = text => JSON.parse(new TextDecoder().decode(Uint8Array.from(
  atob(text.replaceAll('-', '+').replaceAll('_', '/')), c => c.charCodeAt(0))));

export async function isAdmin(token, env, fetcher = fetch) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return false;
    const header = decode(parts[0]), claims = decode(parts[1]), now = Date.now() / 1000;
    if (header.alg !== 'RS256' || claims.aud !== env.FIREBASE_PROJECT_ID ||
        claims.iss !== `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}` ||
        !claims.sub || typeof claims.exp !== 'number' || typeof claims.iat !== 'number' ||
        claims.exp <= now || claims.iat > now + 60 ||
        !env.ADMIN_UID || claims.sub !== env.ADMIN_UID ||
        claims.email?.toLowerCase() !== env.ADMIN_EMAIL) return false;
    if (!keys || keys.expires <= Date.now()) {
      const response = await fetcher('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
      if (!response.ok) return false;
      keys = {value: (await response.json()).keys, expires: Date.now() + 3600000};
    }
    const jwk = keys.value.find(key => key.kid === header.kid);
    if (!jwk) return false;
    const key = await crypto.subtle.importKey('jwk', jwk,
      {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'}, false, ['verify']);
    return crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
      Uint8Array.from(atob(parts[2].replaceAll('-', '+').replaceAll('_', '/')), c => c.charCodeAt(0)),
      new TextEncoder().encode(`${parts[0]}.${parts[1]}`));
  } catch (_) { return false; }
}

export function normalizeVideo(hit) {
  const variants = [hit.videos?.small, hit.videos?.tiny, hit.videos?.medium]
    .filter(video => video?.url?.startsWith('https://cdn.pixabay.com/'));
  // Pixabay's "medium" can be 1440p; prefer mobile-sized original files.
  const video = variants.find(video => video.width <= 1280 && video.height <= 1280)
    ?? variants.at(-1);
  if (!video || !hit.pageURL?.startsWith('https://pixabay.com/')) return null;
  return {id: String(hit.id), provider: 'Pixabay', url: video.url,
    sourceUrl: hit.pageURL, author: String(hit.user ?? ''),
    duration: hit.duration ?? 0, width: video.width, height: video.height,
    tags: hit.tags ?? '', thumbnail: video.thumbnail ?? '',
    audiblePreview: typeof audioPreviewPeaks[video.url] === 'number'
      ? audioPreviewPeaks[video.url] > -65 : null};
}

export function avcProfile(bytes) {
  // avcC: version, AVCProfileIndication, compatibility, level.
  for (let i = 4; i + 8 < bytes.length; i++) {
    if (bytes[i] === 0x61 && bytes[i + 1] === 0x76 && bytes[i + 2] === 0x63 &&
        bytes[i + 3] === 0x43 && bytes[i + 4] === 1) return bytes[i + 5];
  }
  return null;
}

export function mp4HasAudio(bytes) {
  // Handler boxes identify a sound track independently of the audio codec.
  for (let i = 4; i + 16 <= bytes.length; i++) {
    if (bytes[i] === 0x68 && bytes[i + 1] === 0x64 && bytes[i + 2] === 0x6c &&
        bytes[i + 3] === 0x72 && bytes[i + 12] === 0x73 && bytes[i + 13] === 0x6f &&
        bytes[i + 14] === 0x75 && bytes[i + 15] === 0x6e) return true;
  }
  return false;
}

async function inspectVideo(video) {
  let hasAudio = false;
  try {
    for (const range of ['bytes=0-131071', 'bytes=-131072']) {
      const response = await fetch(video.url, {
        headers: {Range: range}, signal: AbortSignal.timeout(8000),
      });
      // Never download an entire video if the origin ignores the byte range.
      if (response.status !== 206) {
        await response.body?.cancel(); return {...video, hasAudio: hasAudio || null};
      }
      const bytes = new Uint8Array(await response.arrayBuffer());
      const profile = avcProfile(bytes);
      if ([110, 122, 244].includes(profile)) return null;
      hasAudio ||= mp4HasAudio(bytes);
      if (hasAudio && profile != null) break;
    }
    return {...video, hasAudio};
  } catch (_) { return {...video, hasAudio: hasAudio || null}; }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url), origin = request.headers.get('Origin') ?? '';
    const allowed = ['https://fashion-business-app.web.app', 'https://fashion-business-app.firebaseapp.com'];
    const local = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
    const headers = {'Content-Type': 'application/json', 'Vary': 'Origin',
      ...(allowed.includes(origin) || local ? {'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Headers': 'Authorization,Content-Type', 'Access-Control-Allow-Methods': 'GET,OPTIONS'} : {})};
    const json = (data, status = 200) => Response.json(data, {status, headers});
    if (request.method === 'OPTIONS') return new Response(null, {status: 204, headers});
    if (request.method === 'GET' && url.pathname === '/collections/animation') {
      const page = Number(url.searchParams.get('page') ?? 1);
      if (!Number.isInteger(page) || page < 1 || page > 3) return json({error: 'Trang không hợp lệ.'}, 400);
      if (page > 1) return json({videos: [], page, hasMore: false});
      const cacheKey = new Request(`${url.origin}/cached-open-movies-v1`);
      const cached = await caches.default.match(cacheKey);
      if (cached) return json(await cached.json());
      const result = {videos: await loadOpenMovies(), page: 1, hasMore: false};
      if (result.videos.length) ctx.waitUntil(caches.default.put(cacheKey,
        Response.json(result, {headers: {'Cache-Control': 'public,max-age=86400'}})));
      return json(result);
    }
    const collectionId = url.pathname.slice('/collections/'.length);
    const collection = url.pathname.startsWith('/collections/') && Object.hasOwn(collections, collectionId)
      ? collections[collectionId] : null;
    if (request.method !== 'GET' || (url.pathname !== '/videos' && !collection)) return json({error: 'Not found'}, 404);
    if (!collection && !await isAdmin((request.headers.get('Authorization') ?? '').replace(/^Bearer /, ''), env)) {
      return json({error: 'Vui lòng đăng nhập tài khoản Admin.'}, 403);
    }
    if (!env.PIXABAY_API_KEY) return json({error: 'Chưa kết nối Pixabay API key ở máy chủ.'}, 503);
    const query = collection ?? (url.searchParams.get('q') ?? 'sneakers').trim().slice(0, 100);
    const page = Number(url.searchParams.get('page') ?? 1);
    if (!Number.isInteger(page) || page < 1 || page > (collection ? 3 : 50)) return json({error: 'Trang không hợp lệ.'}, 400);
    const cacheKey = new Request(`${url.origin}/cached-videos-audible-v2?q=${encodeURIComponent(query)}&page=${page}`);
    const cache = caches.default;
    const saved = await cache.match(cacheKey);
    const pageResult = data => ({...data, hasMore: data.hasMore && (!collection || page < 3)});
    if (saved) return json(pageResult(await saved.json()));
    const upstream = new URL('https://pixabay.com/api/videos/');
    upstream.search = new URLSearchParams({key: env.PIXABAY_API_KEY, q: query, page: String(page),
      per_page: '10', safesearch: 'true', video_type: 'film'}).toString();
    try {
      const response = await fetch(upstream, {signal: AbortSignal.timeout(15000)});
      if (!response.ok) return json({error: response.status === 429
        ? 'Đã hết hạn mức Pixabay. Vui lòng thử lại sau.' : 'Pixabay chưa trả được video. Vui lòng thử lại.'}, 502);
      const data = await response.json();
      const videos = (data.hits ?? []).map(normalizeVideo).filter(Boolean);
      const playable = await Promise.all(videos.map(inspectVideo));
      const result = {videos: playable.filter(Boolean),
        page, hasMore: page * 10 < Math.min(data.totalHits ?? 0, 500)};
      ctx.waitUntil(cache.put(cacheKey, Response.json(result, {headers: {'Cache-Control': 'public,max-age=86400'}})));
      return json(pageResult(result));
    } catch (_) { return json({error: 'Không thể kết nối kho video. Vui lòng thử lại.'}, 502); }
  },
};
