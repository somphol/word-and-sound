import type { ListSource } from '../lib/types'
import type { CSSProperties } from 'react'
import { clampTextScale, clampWordScale, type AccentName, type Settings, type ThemeMode } from '../lib/progress'

const accents = [
  ['en-US', 'American'], ['en-GB', 'British'], ['en-AU', 'Australian'],
  ['en-IN', 'Indian'], ['en-IE', 'Irish'],
] as const

export function SettingsModal({
  settings, voices, onChange, onSource, onResetProgress, onResetSettings, onClose, onCredits,
}: {
  settings: Settings
  voices: SpeechSynthesisVoice[]
  onChange: (next: Settings) => void
  onSource: (source: ListSource) => void
  onResetProgress: () => void
  onResetSettings: () => void
  onClose: () => void
  onCredits: () => void
}) {
  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal settings-modal" role="dialog" aria-modal="true" aria-label="Settings">
        <header className="modal-head"><div><h2>Settings</h2><p>Version {__APP_VERSION__}</p></div><button type="button" className="button small" onClick={onClose}>Close</button></header>
        <section>
          <h3>Appearance</h3>
          <div className="settings-row">
            <span>Theme</span>
            <div className="filter-switch" role="group" aria-label="Theme">
              {([['system', 'Auto'], ['light', 'Light'], ['dark', 'Dark']] as Array<[ThemeMode, string]>).map(([value, label]) => (
                <button key={value} type="button" className={settings.theme === value ? 'active' : ''} aria-pressed={settings.theme === value} onClick={() => onChange({ ...settings, theme: value })}>{label}</button>
              ))}
            </div>
          </div>
          <div className="settings-row">
            <span>Accent</span>
            <div className="swatches" role="group" aria-label="Accent colour">
              {([['blue', 'Blue', '#5b8cff'], ['teal', 'Teal', '#2dd4bf'], ['violet', 'Violet', '#a78bfa'], ['amber', 'Amber', '#f5b544']] as Array<[AccentName, string, string]>).map(([value, label, colour]) => (
                <button
                  key={value}
                  type="button"
                  className={`swatch ${settings.palette === value ? 'active' : ''}`}
                  style={{ '--swatch': colour } as CSSProperties}
                  aria-label={label}
                  aria-pressed={settings.palette === value}
                  title={label}
                  onClick={() => onChange({ ...settings, palette: value })}
                />
              ))}
            </div>
          </div>
        </section>
        <section>
          <h3>Reading</h3>
          <div className="settings-row">
            <span>Text size</span>
            <div className="size-stepper" role="group" aria-label="Text size">
              <button type="button" aria-label="Decrease text size" disabled={settings.textScale <= 0.9} onClick={() => onChange({ ...settings, textScale: clampTextScale(settings.textScale - 0.05) })}>A−</button>
              <output>{Math.round(settings.textScale * 100)}%</output>
              <button type="button" aria-label="Increase text size" disabled={settings.textScale >= 1.3} onClick={() => onChange({ ...settings, textScale: clampTextScale(settings.textScale + 0.05) })}>A+</button>
            </div>
          </div>
          <div className="settings-row">
            <span>Word size</span>
            <div className="size-stepper" role="group" aria-label="Word size">
              <button type="button" aria-label="Decrease word size" disabled={settings.wordScale <= 1} onClick={() => onChange({ ...settings, wordScale: clampWordScale(settings.wordScale - 0.1) })}>A−</button>
              <output>{Math.round(settings.wordScale * 100)}%</output>
              <button type="button" aria-label="Increase word size" disabled={settings.wordScale >= 1.6} onClick={() => onChange({ ...settings, wordScale: clampWordScale(settings.wordScale + 0.1) })}>A+</button>
            </div>
          </div>
          <div className="settings-preview" aria-hidden="true">
            <strong>sound</strong>
            <span>US /saʊnd/</span>
          </div>
        </section>
        <section>
          <h3>Speech</h3>
          <label>Accent
            <select value={settings.accent} onChange={(event) => onChange({ ...settings, accent: event.target.value, voiceURI: '' })}>
              {accents.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>
          <label>Voice
            <select
              value={settings.voiceURI}
              onChange={(event) => {
                const voice = voices.find((item) => item.voiceURI === event.target.value)
                onChange({ ...settings, voiceURI: event.target.value, accent: voice?.lang ?? settings.accent })
              }}
            >
              <option value="">Automatic</option>
              {voices.map((voice) => <option key={voice.voiceURI} value={voice.voiceURI}>{voice.name} · {voice.lang}</option>)}
            </select>
          </label>
          <label>Speech rate <span>{settings.rate.toFixed(1)}×</span>
            <input type="range" min="0.2" max="1.8" step="0.1" value={settings.rate} onChange={(event) => onChange({ ...settings, rate: Number(event.target.value) })} />
          </label>
          <label>Pitch <span>{settings.pitch.toFixed(1)}×</span>
            <input type="range" min="0.5" max="1.8" step="0.1" value={settings.pitch} onChange={(event) => onChange({ ...settings, pitch: Number(event.target.value) })} />
          </label>
        </section>
        <section>
          <h3>Playback</h3>
          <label>Word lists
            <div className="filter-switch">
              <button type="button" className={settings.listSource === 'curated' ? 'active' : ''} onClick={() => { onSource('curated'); onChange({ ...settings, listSource: 'curated' }) }}>Curated</button>
              <button type="button" className={settings.listSource === 'built' ? 'active' : ''} onClick={() => { onSource('built'); onChange({ ...settings, listSource: 'built' }) }}>Built</button>
            </div>
          </label>
          <label>IPA display
            <select value={settings.ipaMode} onChange={(event) => onChange({ ...settings, ipaMode: event.target.value as Settings['ipaMode'] })}>
              <option value="both">US and UK</option><option value="us">US only</option><option value="uk">UK only</option>
            </select>
          </label>
          <label>Repeat
            <select value={settings.repeatCount} onChange={(event) => onChange({ ...settings, repeatCount: Number(event.target.value) })}>
              {[1, 2, 3, 4, 5, 6, 7, 8].map((value) => <option key={value} value={value}>{value}×</option>)}
            </select>
          </label>
          <label>Delay
            <select value={settings.delay} onChange={(event) => onChange({ ...settings, delay: Number(event.target.value) })}>
              {[1, 2, 3, 4, 5, 6, 7, 8].map((value) => <option key={value} value={value}>{value} s</option>)}
            </select>
          </label>
          <button type="button" className="button small" onClick={onCredits}>Credits and licenses</button>
        </section>
        <section>
          <h3>Data</h3>
          <p className="muted-note">Progress, imported lists and recordings stay in this browser.</p>
          <div className="settings-actions">
            <button type="button" className="button small" onClick={onResetSettings}>Reset settings</button>
            <button type="button" className="button small danger" onClick={onResetProgress}>Reset practice history</button>
          </div>
        </section>
      </div>
    </div>
  )
}
