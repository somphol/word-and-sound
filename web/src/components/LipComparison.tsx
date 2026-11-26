import type { Articulation } from '../lib/types'

type LipPosition = 'spread' | 'neutral' | 'rounded'

const SPREAD_VOWELS = new Set(['iː', 'ɪ', 'e', 'ɛ', 'æ', 'ɛː', 'eɪ', 'aɪ', 'ɪə', 'eə', 'aɪə'])

function targetFor(articulation: Articulation): LipPosition {
  if (articulation.shape.lipRound > 0.25) return 'rounded'
  if (articulation.shape.lipRound < -0.05) return 'spread'
  if (articulation.isVowel && SPREAD_VOWELS.has(articulation.id)) return 'spread'
  return 'neutral'
}

const labels: Record<LipPosition, string> = {
  spread: 'spread / smile',
  neutral: 'neutral',
  rounded: 'rounded / kiss',
}

function LipIcon({ position, selected }: { position: LipPosition; selected: boolean }) {
  const dims = position === 'spread'
    ? { w: 78, h: 20, iw: 50, ih: 5 }
    : position === 'neutral'
      ? { w: 58, h: 28, iw: 40, ih: 10 }
      : { w: 38, h: 42, iw: 24, ih: 20 }
  return (
    <svg viewBox="0 0 90 52" className={`lip-icon ${selected ? 'selected' : ''}`} aria-hidden="true">
      <ellipse cx="45" cy="26" rx={dims.w / 2} ry={dims.h / 2} fill="#cc5264" stroke="rgba(255,190,190,.55)" />
      <ellipse cx="45" cy="26" rx={dims.iw / 2} ry={dims.ih / 2} fill="#341018" stroke="rgba(255,255,255,.18)" />
    </svg>
  )
}

export function LipComparison({ articulation }: { articulation: Articulation }) {
  const target = targetFor(articulation)
  return (
    <section className="lip-card">
      <header>
        <span>Lips from the front</span>
        <strong>Target: {labels[target]}</strong>
      </header>
      <div className="lip-options">
        {(['spread', 'neutral', 'rounded'] as LipPosition[]).map((position) => (
          <div key={position} className={`lip-option ${position === target ? 'selected' : ''}`}>
            <LipIcon position={position} selected={position === target} />
            <span>{labels[position]}</span>
          </div>
        ))}
        {articulation.shape.jaw > 0.3 && <span className="jaw-cue">↕ jaw open</span>}
      </div>
      <p>Spread = smile; rounded = kiss. The target is highlighted.</p>
    </section>
  )
}
