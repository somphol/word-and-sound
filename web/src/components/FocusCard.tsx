import type { IpaPart } from '../lib/ipa'
import { useRef } from 'react'
import { clampWordScale, type Settings } from '../lib/progress'
import type { IpaMode } from '../lib/types'
import { Icon } from './Icon'
import { IPAView } from './IPAView'

const accents = [
  ['en-US', 'American'],
  ['en-GB', 'British'],
  ['en-AU', 'Australian'],
  ['en-IN', 'Indian'],
  ['en-IE', 'Irish'],
] as const

export function FocusCard({
  word, parts, target, eyebrow, listTitle, targets, kind, index, total, practised,
  settings, voices, autoplay, isSpeaking, favorite, trouble, isReview,
  onSettings, onOpenSettings, onPlay, onStop, onSlow, onPrevious, onNext, onToggleAutoplay, onReplay,
  onFavorite, onTrouble, onCoach, onRecord, onGotIt, onAgain,
}: {
  word: string | null
  parts: IpaPart[]
  target: string
  eyebrow: string
  listTitle: string
  targets: string[]
  kind: string
  index: number
  total: number
  practised: number
  settings: Settings
  voices: SpeechSynthesisVoice[]
  autoplay: boolean
  isSpeaking: boolean
  favorite: boolean
  trouble: boolean
  isReview: boolean
  onSettings: (next: Partial<Settings>) => void
  onOpenSettings: () => void
  onPlay: () => void
  onStop: () => void
  onSlow: () => void
  onPrevious: () => void
  onNext: () => void
  onToggleAutoplay: () => void
  onReplay: () => void
  onFavorite: () => void
  onTrouble: () => void
  onCoach: () => void
  onRecord: () => void
  onGotIt: () => void
  onAgain: () => void
}) {
  const touchStart = useRef<{ x: number; y: number } | null>(null)
  const hasVoice = voices.some((voice) => voice.lang === settings.accent)
  if (!word) {
    return (
      <article className="focus-card empty">
        <p className="eyebrow">{eyebrow}</p>
        <h1 className="focus-word">Choose a sound</h1>
        <p className="focus-empty-note">Pick a sound tile or a word list to start practising.</p>
      </article>
    )
  }
  return (
    <article
      className="focus-card"
      onTouchStart={(event) => {
        if ((event.target as HTMLElement).closest('button, select, input, a')) return
        touchStart.current = { x: event.touches[0].clientX, y: event.touches[0].clientY }
      }}
      onTouchEnd={(event) => {
        const start = touchStart.current
        touchStart.current = null
        if (!start) return
        const dx = event.changedTouches[0].clientX - start.x
        const dy = event.changedTouches[0].clientY - start.y
        if (Math.abs(dx) < 64 || Math.abs(dx) < Math.abs(dy) * 1.5) return
        if (dx < 0) onNext()
        else onPrevious()
      }}
    >
      <header className="focus-head">
        <div className="focus-heading">
          <p className="eyebrow">{eyebrow}</p>
          <span className="focus-index">{index + 1} <i>/</i> {total}</span>
        </div>
        <div className="focus-tools">
          <button
            type="button"
            className={`icon-button toggle ${favorite ? 'on star' : ''}`}
            onClick={onFavorite}
            aria-pressed={favorite}
            title={favorite ? 'Remove from favorites' : 'Add to favorites'}
          >
            <Icon name="star" filled={favorite} />
          </button>
          <button
            type="button"
            className={`icon-button toggle ${trouble ? 'on flag' : ''}`}
            onClick={onTrouble}
            aria-pressed={trouble}
            title={trouble ? 'Clear difficult mark' : 'Mark as difficult'}
          >
            <Icon name="flag" filled={trouble} />
          </button>
        </div>
      </header>

      <div className="focus-body">
        <h1 className="focus-word">{word}</h1>
        <div className="focus-ipa">
          {parts.map((part) => (
            <span key={part.label}>
              <em>{part.label}</em>
              <IPAView ipa={part.ipa} targets={targets} kind={kind} />
            </span>
          ))}
          {!parts.some((part) => part.label === 'UK') && <span className="chip">UK unavailable</span>}
        </div>
        {target && <span className="chip focus-target">{target}</span>}
      </div>

      <div className="focus-controls">
        <div className="transport">
          <button type="button" className="control icon-only" onClick={onPrevious} title="Previous word" aria-label="Previous word">
            <Icon name="previous" size={20} />
          </button>
          <button
            type="button"
            className={`play-button ${isSpeaking ? 'speaking' : ''}`}
            onClick={isSpeaking ? onStop : onPlay}
            title={isSpeaking ? 'Stop' : 'Play word'}
            aria-label={isSpeaking ? 'Stop' : 'Play word'}
          >
            <Icon name={isSpeaking ? 'pause' : 'play'} size={26} filled />
          </button>
          <button type="button" className="control icon-only" onClick={onNext} title="Next word" aria-label="Next word">
            <Icon name="next" size={20} />
          </button>
        </div>
        <span className="focus-divider" />
        <div className="secondary-controls">
          <button type="button" className="control" onClick={onReplay} title="Replay">
            <Icon name="replay" size={19} /><span>Replay</span>
          </button>
          <button type="button" className="control" onClick={onSlow} title="Slow replay">
            <Icon name="slow" size={19} /><span>Slow</span>
          </button>
          <button type="button" className="control" onClick={onCoach} title="How to make this sound">
            <Icon name="coach" size={19} /><span>Coach</span>
          </button>
          <button type="button" className="control" onClick={onRecord} title="Record yourself">
            <Icon name="mic" size={19} /><span>Record</span>
          </button>
        </div>
        <button
          type="button"
          className={`autoplay-toggle ${autoplay ? 'on' : ''}`}
          aria-pressed={autoplay}
          onClick={onToggleAutoplay}
          title={autoplay ? 'Turn autoplay off' : 'Turn autoplay on'}
        >
          <Icon name="replay" size={17} />
          <span>Autoplay</span>
          <span className="autoplay-state">{autoplay ? 'On' : 'Off'}</span>
        </button>
      </div>

      {isReview && (
        <div className="focus-review">
          <button type="button" className="button" onClick={onAgain}>Again</button>
          <button type="button" className="button primary" onClick={onGotIt}>Got it</button>
        </div>
      )}

      <div className="focus-foot">
        <div className="focus-progress">
          <div className="focus-progress-label">
            <span>{practised} of {total} practised</span>
            <span>{listTitle}</span>
          </div>
          <div className="progress-track">
            <span style={{ width: `${total ? (practised / total) * 100 : 0}%` }} />
          </div>
        </div>
        <button type="button" className="playback-link" onClick={onOpenSettings}>
          <Icon name="settings" size={15} /> Playback
        </button>
      </div>

      <div className="playback-strip">
        <label>Accent
          <select value={settings.accent} onChange={(event) => onSettings({ accent: event.target.value, voiceURI: '' })}>
            {accents.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </label>
        <label>Repeat
          <select value={settings.repeatCount} onChange={(event) => onSettings({ repeatCount: Number(event.target.value) })}>
            {[1, 2, 3, 4, 5, 6, 7, 8].map((value) => <option key={value} value={value}>{value}×</option>)}
          </select>
        </label>
        <label>Delay
          <select value={settings.delay} onChange={(event) => onSettings({ delay: Number(event.target.value) })}>
            {[1, 2, 3, 4, 5, 6, 7, 8].map((value) => <option key={value} value={value}>{value} s</option>)}
          </select>
        </label>
        <label>IPA
          <select value={settings.ipaMode} onChange={(event) => onSettings({ ipaMode: event.target.value as IpaMode })}>
            <option value="both">US + UK</option>
            <option value="us">US only</option>
            <option value="uk">UK only</option>
          </select>
        </label>
        <span className="size-stepper" role="group" aria-label="Word size">
          <span className="size-label">Word</span>
          <button
            type="button"
            aria-label="Decrease word size"
            disabled={settings.wordScale <= 1}
            onClick={() => onSettings({ wordScale: clampWordScale(settings.wordScale - 0.1) })}
          >A−</button>
          <output>{Math.round(settings.wordScale * 100)}%</output>
          <button
            type="button"
            aria-label="Increase word size"
            disabled={settings.wordScale >= 1.6}
            onClick={() => onSettings({ wordScale: clampWordScale(settings.wordScale + 0.1) })}
          >A+</button>
        </span>
        <span className="voice-name">
          <span className={`voice-dot ${hasVoice ? '' : 'missing'}`} />
          {voices.find((voice) => voice.lang === settings.accent)?.name ?? 'No voice'}
        </span>
      </div>
    </article>
  )
}
