import { useState } from 'react'
import type { AppData, Articulation, SoundTile } from '../lib/types'
import { targetDescription } from '../lib/ipa'
import { IPAView } from './IPAView'
import { MouthDiagram } from './MouthDiagram'
import { LipComparison } from './LipComparison'
import { VowelChart } from './VowelChart'

export function CoachModal({
  tile, components, articulation, samples, us, uk, ipaMode, targets, kind, onClose, onPlay, onRecord,
}: {
  tile: SoundTile
  components: Articulation[]
  articulation: Articulation[]
  samples: string[]
  us: Record<string, string>
  uk: Record<string, string>
  ipaMode: 'both' | 'us' | 'uk'
  targets: string[]
  kind: string
  onClose: () => void
  onPlay: (word: string, slow?: boolean) => void
  onRecord: () => void
}) {
  const [selected, setSelected] = useState(0)
  const current = components[Math.min(selected, Math.max(0, components.length - 1))]
  if (!current) {
    return (
      <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
        <div className="modal coach-modal"><p>No articulation guide for this tile yet.</p><button type="button" className="button" onClick={onClose}>Close</button></div>
      </div>
    )
  }
  const blend = components.length > 1
  const displayName = blend ? `Blend: ${components.map((item) => item.symbol).join(' + ')}` : current.name
  const ipa = ipaMode === 'uk' ? uk[tile.exampleWord.toLowerCase()] : ipaMode === 'us' ? us[tile.exampleWord.toLowerCase()] : (uk[tile.exampleWord.toLowerCase()] ?? us[tile.exampleWord.toLowerCase()])

  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal coach-modal" role="dialog" aria-modal="true" aria-label={`${tile.label} articulation coach`}>
        <header className="coach-head">
          <div className="coach-title">
            <strong className="coach-symbol">{tile.label}</strong>
            <div><h2>{displayName}</h2><p>{targetDescription(tile)} {blend ? '· blend' : current.isVowel ? '' : `· ${current.place} · ${current.manner}`} · {current.voiced ? 'voice on' : 'voice off'}{current.lengthLabel ? ` · ${current.lengthLabel}` : ''}</p></div>
          </div>
          <button type="button" className="button small" onClick={onClose}>Close</button>
        </header>

        {blend && (
          <div className="blend-strip">
            <p>Say each position without adding a vowel between.</p>
            <div>
              {components.map((component, index) => (
                <span key={component.id}>
                  <button type="button" className={`blend-component ${selected === index ? 'active' : ''}`} onClick={() => setSelected(index)}>
                    <MouthDiagram articulation={component} compact />
                    <b>{component.symbol}</b>
                  </button>
                  {index < components.length - 1 && <i>→</i>}
                </span>
              ))}
            </div>
          </div>
        )}

        <div className="coach-body">
          <div className="coach-left">
            <MouthDiagram articulation={current} />
            <div className="legend"><span className="target-dot" /> target zone <span className="air-dot" /> airflow <span className="voice-dot" /> voice <span className="rest-dot" /> rest</div>
            <p className="legend-note">Solid tongue = target; dashed outline = rest.</p>
            <LipComparison articulation={current} />
            <div className="coach-actions">
              <button type="button" className="button small" onClick={() => onPlay(tile.exampleWord)}>Hear example</button>
              <button type="button" className="button small" onClick={() => onPlay(tile.exampleWord, true)}>Slow</button>
              <button type="button" className="button small" onClick={onRecord}>Record</button>
            </div>
            <div className="try-card">
              <small>Try this</small>
              <strong>{tile.exampleWord}</strong>
              <IPAView ipa={ipa ?? '—'} targets={targets} kind={kind} />
              <p>Lead with the target position, then say the word. Repeat slowly, then at normal speed.</p>
            </div>
            {samples.length > 0 && (
              <div className="sample-card">
                <small>Hear it in words</small>
                {samples.slice(0, 4).map((word) => (
                  <div key={word} className="sample-row">
                    <span>{word}</span>
                    <IPAView ipa={ipaMode === 'us' ? us[word.toLowerCase()] ?? '' : ipaMode === 'uk' ? uk[word.toLowerCase()] ?? '' : (uk[word.toLowerCase()] ?? us[word.toLowerCase()] ?? '')} targets={targets} kind={kind} />
                    <button type="button" className="icon-button" onClick={() => onPlay(word)} aria-label={`Play ${word}`}>◔</button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="coach-right">
            {current.isVowel && <VowelChart articulation={current} all={articulation} />}
            {current.isVowel && (
              <section className="coach-section">
                <h3>Anchor and contrasts</h3>
                <p className="muted-note">Front vowels left, back vowels right; high vowels at the top.</p>
                <div className="anchor-buttons">
                  {current.anchorWord && <button type="button" className="button small primary" onClick={() => onPlay(current.anchorWord!)}>{current.symbol} · {current.anchorWord}</button>}
                  {current.contrasts.map((id) => {
                    const contrast = articulation.find((item) => item.id === id)
                    return contrast?.anchorWord ? (
                      <button key={id} type="button" className="button small" onClick={() => onPlay(contrast.anchorWord!)}>{contrast.symbol} · {contrast.anchorWord}</button>
                    ) : null
                  })}
                </div>
                {current.lengthLabel && (
                  <div className="length-line">
                    <span>Length</span>
                    <div className="length-track"><i style={{ width: current.lengthLabel === 'short' ? '36%' : '100%' }} /></div>
                    <b>{current.lengthLabel}</b>
                  </div>
                )}
              </section>
            )}
            {blend && (
              <section className="coach-section">
                <h3>Say the whole blend</h3>
                {components.map((component) => (
                  <p key={component.id}><b>{component.symbol}</b> {component.steps[0]}</p>
                ))}
                <p className="muted-note">Do not insert a vowel between the consonants.</p>
                <p><b className="warn">extra vowel</b> Keep moving; do not relax between sounds.</p>
                <p><b className="warn">dropped sound</b> Hold each position briefly, then blend faster.</p>
              </section>
            )}
            <section className="coach-section">
              <h3>How to make it</h3>
              {current.steps.map((step, index) => <p key={step}><span className="step-number">{index + 1}</span>{step}</p>)}
            </section>
            {current.errors.length > 0 && (
              <section className="coach-section">
                <h3>If it sounds like…</h3>
                {current.errors.map((error) => <p key={error.heardAs}><b className="warn">{error.heardAs}</b> {error.fix}</p>)}
              </section>
            )}
            {current.anchors.length > 0 && (
              <section className="coach-section">
                <h3>Physical anchors</h3>
                {current.anchors.map((anchor) => <p key={anchor}>☞ {anchor}</p>)}
              </section>
            )}
            <section className="coach-section">
              <h3>Practice ladder</h3>
              <p>1. Hold the position. 2. Say the example. 3. Say it slowly. 4. Record and compare.</p>
              <div className="coach-actions">
                <button type="button" className="button small" onClick={() => onPlay(tile.exampleWord)}>Hear example</button>
                <button type="button" className="button small" onClick={() => onPlay(tile.exampleWord, true)}>Slow</button>
                <button type="button" className="button small" onClick={onRecord}>Record myself</button>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  )
}
