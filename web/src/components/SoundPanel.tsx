import type { AppData, ListSource, SoundTile, WordProgress } from '../lib/types'
import { categoryForTile, componentsFor, wordsForTile } from '../lib/data'
import { ipaParts, targetDescription } from '../lib/ipa'
import { IPAView } from './IPAView'

export function SoundPanel({
  data, category, source, activeTile, progress, onSelect, onCoach, onSourceChange,
}: {
  data: AppData
  category: string
  source: ListSource
  activeTile: SoundTile | null
  progress: Record<string, WordProgress>
  onSelect: (tile: SoundTile) => void
  onCoach: (tile: SoundTile) => void
  onSourceChange?: (source: ListSource) => void
}) {
  const group = data.library.categories.find((item) => item.id === category) ?? data.library.categories[0]
  const single = group.tiles.filter((tile) => tile.group === 'single')
  const blends = group.tiles.filter((tile) => tile.group === 'blend')
  const vowels = group.tiles.filter((tile) => tile.group === 'vowel')
  const sections = group.id === 'vowel'
    ? [['Vowel sounds', vowels] as const]
    : group.id === 'starting'
      ? [['Single sounds', single] as const, ['Starting blends', blends] as const]
      : [['Single endings', single] as const, ['Ending blends', blends] as const]

  const count = (tile: SoundTile) => wordsForTile(data, tile, source).length
  const activeWords = activeTile ? wordsForTile(data, activeTile, source) : []
  const practised = activeWords.filter((word) => (progress[word.toLowerCase()]?.listens ?? 0) > 0).length
  const guide = activeTile ? componentsFor(activeTile.label, data.articulation)[0] : null

  return (
    <section className="sound-panel">
      <div className="panel-title">
        <div>
          <h2>{group.title}</h2>
          <span>{group.tiles.length} sounds · {source === 'built' ? 'pattern-built' : 'curated'}</span>
        </div>
        {onSourceChange && (
          <div className="source-switch panel-source" role="group" aria-label="List source">
            <button type="button" className={source === 'curated' ? 'active' : ''} onClick={() => onSourceChange('curated')}>Curated</button>
            <button type="button" className={source === 'built' ? 'active' : ''} onClick={() => onSourceChange('built')}>Built</button>
          </div>
        )}
      </div>

      {activeTile && (
        <div className="sound-example">
          <div className="sound-example-head">
            <strong>{activeTile.exampleWord}</strong>
            <span className="label-chip">/ {activeTile.label} /</span>
            <span className="muted">{count(activeTile)} words</span>
          </div>
          <div className="ipa-line">
            {ipaParts(data.us, data.uk, activeTile.exampleWord, 'both').map((part) => (
              <span key={part.label}>
                <em>{part.label}</em>
                <IPAView ipa={part.ipa} targets={activeTile.targets} kind={activeTile.kind} />
              </span>
            ))}
            <span className="chip">{targetDescription(activeTile)}</span>
            {!data.uk[activeTile.exampleWord.toLowerCase()] && <span className="chip">UK unavailable</span>}
          </div>
          <p className="tip">{guide?.steps[0] ?? 'Listen, then repeat at a comfortable speed.'}</p>
          <button type="button" className="button small" onClick={() => onCoach(activeTile)}>How to make this sound</button>
          <div className="progress-line">
            <div className="progress-track"><span style={{ width: `${activeWords.length ? (practised / activeWords.length) * 100 : 0}%` }} /></div>
            <span>{practised} / {activeWords.length} practised</span>
          </div>
        </div>
      )}

      {sections.map(([title, tiles]) => (
        <div className="tile-section" key={title}>
          <h3>{title}</h3>
          <div className="tile-grid">
            {tiles.map((tile) => (
              <button
                key={tile.id}
                type="button"
                className={`tile ${activeTile?.id === tile.id ? 'active' : ''}`}
                onClick={() => onSelect(tile)}
                title={`${tile.label} — ${tile.exampleWord} · ${count(tile)} words`}
              >
                <strong>{tile.label}</strong>
                <span>{tile.exampleWord}</span>
              </button>
            ))}
          </div>
        </div>
      ))}
    </section>
  )
}
