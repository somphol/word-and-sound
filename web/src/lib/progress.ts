import type { ImportedList, WordProgress } from './types'

const PROGRESS_KEY = 'word-and-sound:progress:v1'
const POSITIONS_KEY = 'word-and-sound:positions:v1'
const IMPORTED_KEY = 'word-and-sound:imported:v1'
const SETTINGS_KEY = 'word-and-sound:settings:v1'

export const REVIEW_INTERVALS = [1, 3, 7, 14, 30]

function safeRead<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw ? (JSON.parse(raw) as T) : fallback
  } catch {
    return fallback
  }
}

function safeWrite(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // Storage can be unavailable in private mode; the session still works.
  }
}

export function loadProgress(): Record<string, WordProgress> {
  return safeRead<Record<string, WordProgress>>(PROGRESS_KEY, {})
}

export function saveProgress(progress: Record<string, WordProgress>) {
  safeWrite(PROGRESS_KEY, progress)
}

export function loadPositions(): Record<string, string> {
  return safeRead<Record<string, string>>(POSITIONS_KEY, {})
}

export function savePositions(positions: Record<string, string>) {
  safeWrite(POSITIONS_KEY, positions)
}

export function loadImported(): ImportedList[] {
  return safeRead<ImportedList[]>(IMPORTED_KEY, [])
}

export function saveImported(lists: ImportedList[]) {
  safeWrite(IMPORTED_KEY, lists)
}

export type ThemeMode = 'system' | 'light' | 'dark'
export type AccentName = 'blue' | 'teal' | 'violet' | 'amber'

export interface Settings {
  listSource: 'curated' | 'built'
  textScale: number
  wordScale: number
  theme: ThemeMode
  palette: AccentName
  accent: string
  voiceURI: string
  repeatCount: number
  delay: number
  rate: number
  pitch: number
  ipaMode: 'both' | 'us' | 'uk'
  category: string
  tile: string
  mixed: string
}

export const defaultSettings: Settings = {
  listSource: 'built',
  textScale: 1,
  wordScale: 1,
  theme: 'dark',
  palette: 'blue',
  accent: 'en-US',
  voiceURI: '',
  repeatCount: 1,
  delay: 2,
  rate: 1,
  pitch: 1,
  ipaMode: 'both',
  category: 'starting',
  tile: 'startingD',
  mixed: 'core_3k',
}

export function loadSettings(): Settings {
  return { ...defaultSettings, ...safeRead<Partial<Settings>>(SETTINGS_KEY, {}) }
}

export function saveSettings(settings: Settings) {
  safeWrite(SETTINGS_KEY, settings)
}

export function clampTextScale(value: number): number {
  return Math.min(1.3, Math.max(0.9, Math.round(value * 20) / 20))
}

export function clampWordScale(value: number): number {
  return Math.min(1.6, Math.max(1, Math.round(value * 10) / 10))
}

export function nextStep(current: number, correct: boolean): number {
  if (!correct) return 0
  return Math.min(Math.max(0, current) + 1, REVIEW_INTERVALS.length - 1)
}

export function nextDue(step: number, from = Date.now()): number {
  const index = Math.min(Math.max(0, step), REVIEW_INTERVALS.length - 1)
  return from + REVIEW_INTERVALS[index] * 86_400_000
}

export function isDue(due: number | null, now = Date.now()): boolean {
  return due !== null && due <= now
}

export function reviewWords(progress: Record<string, WordProgress>, now = Date.now()): string[] {
  return Object.values(progress)
    .filter((item) => item.favorite || item.trouble || isDue(item.due, now))
    .sort((a, b) => {
      const left = a.due ?? Number.MAX_SAFE_INTEGER
      const right = b.due ?? Number.MAX_SAFE_INTEGER
      return left === right ? a.word.localeCompare(b.word) : left - right
    })
    .slice(0, 500)
    .map((item) => item.word)
}

export function dueCount(progress: Record<string, WordProgress>, now = Date.now()): number {
  return Object.values(progress).filter((item) => isDue(item.due, now)).length
}

const BANNED = new Set(['n\'t'])

export function parseWordList(text: string): string[] {
  const words: string[] = []
  const seen = new Set<string>()
  const lines = text.split(/\r?\n/)
  lines.forEach((rawLine, index) => {
    let line = rawLine.trim().replace(/^\uFEFF/, '')
    if (!line) return
    const hadDelimiter = line.includes(',') || line.includes('\t')
    line = line.split(',')[0].split('\t')[0].trim().replace(/^["']|["']$/g, '')
    if (index === 0 && hadDelimiter && ['word', 'lemma', 'headword', 'term'].includes(line.toLowerCase())) return
    line = line.replace(/\\'/g, "'")
    line = line.replace(/[0-9]+$/, '')
    if (!/^[A-Za-z][A-Za-z'-]*$/.test(line)) return
    if (line.length === 1 && line !== 'a' && line !== 'I') return
    if (BANNED.has(line.toLowerCase())) return
    const key = line.toLowerCase()
    if (!seen.has(key)) {
      seen.add(key)
      words.push(line)
    }
  })
  return words.slice(0, 50_000)
}
