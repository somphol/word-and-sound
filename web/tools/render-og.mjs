import { execFileSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { unlink } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { chromium } from 'playwright-core'

const here = dirname(fileURLToPath(import.meta.url))
const publicDir = join(here, '..', 'public')
const source = pathToFileURL(join(here, 'og.html')).href
const temporary = join(publicDir, 'og@2x.png')
const target = join(publicDir, 'og.png')

const candidates = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
].filter(Boolean)
const executablePath = candidates.find((candidate) => existsSync(candidate))
if (!executablePath) {
  throw new Error('No Chrome found. Set CHROME_PATH to a Chrome or Chromium binary.')
}

const browser = await chromium.launch({ executablePath, headless: true })
const page = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 2 })
await page.goto(source, { waitUntil: 'load' })
await page.waitForTimeout(250)
await page.screenshot({ path: temporary })
await browser.close()

try {
  execFileSync('sips', ['-z', '630', '1200', temporary, '--out', target], { stdio: 'ignore' })
  await unlink(temporary)
} catch {
  // Without sips (Linux CI), keep the 2x render as the share image.
  const { rename } = await import('node:fs/promises')
  await rename(temporary, target)
}
console.log(`Wrote ${target}`)
