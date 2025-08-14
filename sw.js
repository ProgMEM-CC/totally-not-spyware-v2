const CACHE_NAME = 'tns-v2-cache-v6';
const ICON_CACHE = 'tns-v2-icons-v4';

// Resolve URLs relative to the service worker scope (works on GitHub Pages project paths)
const SCOPE_BASE = (self.registration && self.registration.scope) || self.location.href;
const toScopeURL = (u) => new URL(u, SCOPE_BASE);

// Core files + pages (relative to SW scope)
const urlsToCacheRel = [
  'index.html',
  'exploit-compact.html',
  'tns-pwa/dist/exploit-compact.html',
  'tns-pwa/dist/legacy.html',
  'legacy.html',
  'manifest.json',
  'utils.js',
  'helper.js',
  'int64.js',
  'stages.js',
  'offsets.js',
  'pwn.js',
  'icons/icon-180x180.png',
  'icons/icon-192x192.png',
  'icons/icon-512x512.png',
  'icons/TotallyNotSpyware.png'
];

// Local icons we want available offline
const ICONS_TO_PRECACHE_REL = [
  'icons/icon-60x60.png',
  'icons/icon-76x76.png',
  'icons/icon-120x120.png',
  'icons/icon-152x152.png',
  'icons/icon-167x167.png',
  'icons/icon-180x180.png'
];

// External icon fallbacks (opaque responses are fine to cache)
const EXTERNAL_ICONS = [
  'https://totally.not.spyware.lol/img/amazing.png',
  'https://totally.not.spyware.lol/img/ios-icon.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-60x60.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-76x76.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-120x120.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-152x152.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-167x167.png',
  'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-180x180.png'
];

// Map remote icons into local cache keys so pages can always reference local paths
const REMOTE_TO_LOCAL_ICON_MAP = [
  // Prefer mapping the primary app logo to a reliable local key
  ['icons/icon-180x180.png', 'https://totally.not.spyware.lol/img/ios-icon.png'],
  ['icons/icon-60x60.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-60x60.png'],
  ['icons/icon-76x76.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-76x76.png'],
  ['icons/icon-120x120.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-120x120.png'],
  ['icons/icon-152x152.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-152x152.png'],
  ['icons/icon-167x167.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-167x167.png'],
  ['icons/icon-180x180.png', 'https://raw.githubusercontent.com/wh1te4ever/totally-not-spyware-v2/0d1bf6d0ea35f6726d83c3da758308444cf8d16f/icons/icon-180x180.png'],
  ['icons/TotallyNotSpyware.png', 'https://totally.not.spyware.lol/img/amazing.png']
];

// Install event - cache resources
self.addEventListener('install', event => {
  event.waitUntil((async () => {
    // Take control ASAP so first reload is controlled
    if (self.skipWaiting) self.skipWaiting();
    const core = await caches.open(CACHE_NAME);
    await core.addAll(urlsToCacheRel.map(u => toScopeURL(u)));
    const iconCache = await caches.open(ICON_CACHE);
    // Precache local icons
    await iconCache.addAll(ICONS_TO_PRECACHE_REL.map(u => toScopeURL(u)));
    // Try to precache external icons (ignore CORS/opaque concerns)
    await Promise.allSettled(EXTERNAL_ICONS.map(u => iconCache.add(u).catch(()=>null)));
    // Populate remote icons under local keys for reliable same-origin access
    await Promise.allSettled(REMOTE_TO_LOCAL_ICON_MAP.map(async ([localPath, remoteUrl]) => {
      try {
        const res = await fetch(remoteUrl, { mode: 'no-cors' });
        await iconCache.put(toScopeURL(localPath), res.clone());
      } catch (_) { /* ignore */ }
    }));
  })());
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);

  // Ensure navigations always have an offline fallback
  if (req.mode === 'navigate' || (req.headers.get('accept') || '').includes('text/html')) {
    event.respondWith((async () => {
      const core = await caches.open(CACHE_NAME);
      try {
        const res = await fetch(req);
        // Cache a copy for future offline visits (same-origin only)
        if (url.origin === location.origin) core.put(req, res.clone());
        return res;
      } catch (e) {
        return (await core.match(toScopeURL('tns-pwa/dist/exploit-compact.html')))
            || (await core.match(toScopeURL('exploit-compact.html')))
            || (await core.match(toScopeURL('index.html')))
            || Response.error();
      }
    })());
    return;
  }
  // Prefer icon cache for icon requests
  if (url.pathname.includes('/icons/') || /icon-\d+x\d+\.png$/.test(url.pathname)) {
    event.respondWith((async () => {
      const iconCache = await caches.open(ICON_CACHE);
      const cached = await iconCache.match(req, { ignoreVary: true, ignoreSearch: true });
      if (cached) return cached;
      try {
        const res = await fetch(req, { mode: 'no-cors' });
        // Only cache successful responses; avoid persisting 404s
        if (res && (res.ok || res.type === 'opaque')) {
          iconCache.put(req, res.clone());
          return res;
        }
        throw new Error('Bad icon response');
      } catch (e) {
        // Fallback to core cache
        const core = await caches.open(CACHE_NAME);
        const fallback = await iconCache.match(toScopeURL('icons/icon-180x180.png'))
          || await core.match(toScopeURL('icons/icon-180x180.png'))
          || await core.match(toScopeURL('icons/icon-192x192.png'))
          || await core.match(toScopeURL('icons/icon-512x512.png'))
          || await core.match('/icons/TotallyNotSpyware.png');
        return fallback || Response.error();
      }
    })());
    return;
  }

  // Default: network-first for all GETs (prefer fresh when online), fallback to cache
  event.respondWith((async () => {
    const core = await caches.open(CACHE_NAME);
    try {
      const res = await fetch(req);
      // Opportunistically cache GETs under same-origin
      if (req.method === 'GET' && url.origin === location.origin) {
        core.put(req, res.clone());
      }
      return res;
    } catch (e) {
      const cached = await core.match(req);
      if (cached) return cached;
      // Offline fallback to index or exploit-compact
      return (await core.match(toScopeURL('tns-pwa/dist/exploit-compact.html'))) 
          || (await core.match(toScopeURL('exploit-compact.html'))) 
          || (await core.match(toScopeURL('index.html'))) 
          || Response.error();
    }
  })());
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keep = new Set([CACHE_NAME, ICON_CACHE]);
    const names = await caches.keys();
    await Promise.all(names.map(n => keep.has(n) ? null : caches.delete(n)));
    if (self.clients && self.clients.claim) self.clients.claim();
  })());
});

// Allow page to trigger immediate activation
self.addEventListener('message', (event) => {
  try {
    const data = event && event.data;
    if (data && (data.type === 'SKIP_WAITING' || data === 'SKIP_WAITING')) {
      if (self.skipWaiting) self.skipWaiting();
    }
  } catch (_) { /* noop */ }
});
