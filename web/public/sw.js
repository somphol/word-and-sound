const CACHE = 'word-and-sound-v3'
const CORE = [
  './',
  './index.html',
  './manifest.webmanifest',
  './data/library.json',
  './data/phonetics_us.json',
  './data/phonetics_uk.json',
  './data/pattern_lists.json',
  './data/minimal_pairs.json',
  './data/provenance.json',
  './data/articulation.json'
]

async function precache() {
  const cache = await caches.open(CACHE)
  await cache.addAll(CORE)
  // Hashed JS/CSS names come from the build, so read them from index.html
  // instead of hardcoding them here.
  try {
    const response = await fetch('./index.html', { cache: 'no-cache' })
    const html = await response.text()
    const assets = [...html.matchAll(/(?:src|href)="([^"]+)"/g)]
      .map((match) => match[1])
      .filter((url) => !url.startsWith('http') && !url.startsWith('data:'))
      .map((url) => new URL(url, self.location.href).href)
    await Promise.allSettled(assets.map((url) => cache.add(url)))
  } catch {
    // The shell is still usable; assets will be cached on first use.
  }
}

self.addEventListener('install', (event) => {
  event.waitUntil(precache().then(() => self.skipWaiting()))
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener('fetch', (event) => {
  const request = event.request
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone()
            caches.open(CACHE).then((cache) => cache.put('./index.html', copy))
          }
          return response
        })
        .catch(() => caches.match('./index.html', { ignoreVary: true }).then((cached) => cached ?? caches.match('./', { ignoreVary: true })))
    )
    return
  }

  event.respondWith(
    caches.match(request, { ignoreVary: true }).then((cached) => {
      if (cached) return cached
      return fetch(request).then((response) => {
        if (response.ok) {
          const copy = response.clone()
          caches.open(CACHE).then((cache) => cache.put(request, copy))
        }
        return response
      })
    })
  )
})
