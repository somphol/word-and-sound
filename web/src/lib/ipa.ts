import type { IpaMode, SoundTile } from './types'

export interface IpaPart {
  label: 'US' | 'UK'
  ipa: string
}

export function ipaParts(us: Record<string, string>, uk: Record<string, string>, word: string, mode: IpaMode): IpaPart[] {
  const key = word.toLowerCase()
  const parts: IpaPart[] = []
  if (mode !== 'uk' && us[key]) parts.push({ label: 'US', ipa: us[key] })
  if (mode !== 'us' && uk[key]) parts.push({ label: 'UK', ipa: uk[key] })
  return parts
}

export function rowIPA(us: Record<string, string>, uk: Record<string, string>, word: string, mode: IpaMode): string {
  const key = word.toLowerCase()
  if (mode === 'us') return us[key] ?? '—'
  if (mode === 'uk') return uk[key] ?? '—'
  return uk[key] ?? us[key] ?? '—'
}

function candidates(target: string): string[] {
  const values = [target]
  const alternatives = [
    target.replaceAll('r', 'ɹ'),
    target.replaceAll('g', 'ɡ'),
    target.replaceAll('l', 'ɫ'),
  ]
  for (const value of alternatives) if (!values.includes(value)) values.push(value)
  return values
}

export interface Highlight {
  prefix: string
  hit: string
  suffix: string
}

export function highlight(ipa: string, targets: string[], kind: string): Highlight | null {
  for (const target of targets) {
    for (const candidate of candidates(target)) {
      const index = kind.startsWith('coda') ? ipa.lastIndexOf(candidate) : ipa.indexOf(candidate)
      if (index >= 0) {
        return {
          prefix: ipa.slice(0, index),
          hit: ipa.slice(index, index + candidate.length),
          suffix: ipa.slice(index + candidate.length),
        }
      }
    }
  }
  return null
}

export function targetDescription(tile: SoundTile | null): string {
  if (!tile) return ''
  if (tile.kind === 'onset' || tile.kind === 'blend') return `initial /${tile.label}/`
  if (tile.kind === 'coda' || tile.kind === 'codaBlend') return `final /${tile.label}/`
  return tile.label.includes('/') ? `vowel ${tile.label}` : `vowel /${tile.label}/`
}
