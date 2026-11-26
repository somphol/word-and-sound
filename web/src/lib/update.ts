export async function forceRefresh(): Promise<void> {
  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations()
      await Promise.all(registrations.map((registration) => registration.unregister()))
    }
  } catch {
    // Continue: a normal reload is still better than nothing.
  }
  try {
    if ('caches' in window) {
      const keys = await caches.keys()
      await Promise.all(keys.map((key) => caches.delete(key)))
    }
  } catch {
    // Cache storage can be unavailable in private mode.
  }
  const url = new URL(window.location.href)
  url.searchParams.set('refresh', Date.now().toString())
  window.location.replace(url.toString())
}
