import type { AppData, IpaMode } from '../lib/types'
import type { IpaPart } from '../lib/ipa'
import type { Settings } from '../lib/progress'
import { IPAView } from './IPAView'

const accents = [
  ['en-US', 'American'],
  ['en-GB', 'British'],
  ['en-AU', 'Australian'],
  ['en-IN', 'Indian'],
  ['en-IE', 'Irish'],
] as const

export function PlayerBar({
  word, parts, target, progressText, listTitle, targets, kind, settings, voices, autoplay,
  isSpeaking, favorite, trouble, isReview, onSettings, onPlay, onSlow, onPrevious, onNext,
  onToggleAutoplay, onReplay, onFavorite, onTrouble, onCoach, onRecord, onGotIt, onAgain,
}: {
  data: AppData
  word: string | null
  parts: IpaPart[]
  target: string
  progressText: string
  listTitle: string
  targets: string[]
  kind: string
  settings: Settings
  voices: SpeechSynthesisVoice[]
  autoplay: boolean
  isSpeaking: boolean
  favorite: boolean
  trouble: boolean
  isReview: boolean
  onSettings: (next: Partial<Settings>) => void
  onPlay: () => void
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
  if (!word) {
    return <footer className="player empty"><span>Select a word to hear it.</span></footer>
  }
  const hasVoice = voices.some((voice) => voice.lang === settings.accent)
  return (
    <footer className="player">
      <div className="player-main">
        <div className="player-word">
          <h2>{word}</h2>
          <div className="ipa-line">
            {parts.map((part) => (
              <span key={part.label}>
                <em>{part.label}</em>
                <IPAView ipa={part.ipa} targets={targets} kind={kind} />
              </span>
            ))}
            {target && <span className="chip">{target}</span>}
            {!parts.some((part) => part.label === 'UK') && <span className="chip">UK unavailable</span>}
          </div>
          <p><span>{progressText}</span> · {listTitle}</p>
        </div>
        <div className="player-controls">
          <button type="button" className="icon-button" onClick={onPrevious} title="Previous word">◀</button>
          <button type="button" className={`play-button ${isSpeaking ? 'speaking' : ''}`} onClick={onPlay} title="Play current word">▶</button>
          <button type="button" className="icon-button" onClick={onNext} title="Next word">▶|</button>
          <button type="button" className="icon-button" onClick={onReplay} title="Replay">◔</button>
          <button type="button" className="icon-button" onClick={onSlow} title="Slow replay">🐢</button>
          <button type="button" className="icon-button" onClick={onCoach} title="How to make this sound">◕</button>
          <button type="button" className="icon-button" onClick={onRecord} title="Record yourself">🎙</button>
          <button type="button" className={`star-button ${favorite ? 'on' : ''}`} onClick={onFavorite} title="Favorite">★</button>
          <button type="button" className={`flag-button ${trouble ? 'on' : ''}`} onClick={onTrouble} title="Difficult">⚑</button>
          {hasVoice ? <span className="voice-dot" title="Voice available" /> : <span className="voice-dot missing" title="No voice for this accent" />}
        </div>
        <label className="autoplay">
          <input type="checkbox" checked={autoplay} onChange={onToggleAutoplay} />
          Auto Play
        </label>
      </div>
      <div className="player-options">
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
            <option value="both">US and UK</option>
            <option value="us">US only</option>
            <option value="uk">UK only</option>
          </select>
        </label>
        {isReview && (
          <span className="review-actions">
            <button type="button" className="button small" onClick={onGotIt}>Got it</button>
            <button type="button" className="button small" onClick={onAgain}>Again</button>
          </span>
        )}
        <span className="voice-name">{voices.find((voice) => voice.lang === settings.accent)?.name ?? 'No voice'}</span>
      </div>
    </footer>
  )
}
