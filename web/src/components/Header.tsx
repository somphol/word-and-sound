import type { ListSource } from '../lib/types'

const tabs = [
  ['starting', 'Starting'],
  ['vowel', 'Vowel'],
  ['ending', 'Ending'],
  ['mixed', 'Mixed'],
] as const

export function Header({
  category, source, onCategory, onSource, onSearch, onPractice, onImport, onSettings, onCredits, version, reviewCount,
}: {
  category: string
  source: ListSource
  onCategory: (id: string) => void
  onSource: (source: ListSource) => void
  onSearch: () => void
  onPractice: () => void
  onImport: () => void
  onSettings: () => void
  onCredits: () => void
  version: string
  reviewCount: number
}) {
  return (
    <header className="header">
      <div className="brand">
        <h1>Word &amp; Sound</h1>
        <p>English pronunciation drills with IPA and speech <span>· v{version}</span></p>
      </div>
      <nav className="tabs" aria-label="Sound categories">
        {tabs.map(([id, label]) => (
          <button key={id} type="button" className={category === id ? 'active' : ''} onClick={() => onCategory(id)}>
            {label}
          </button>
        ))}
      </nav>
      <div className="header-actions">
        {category !== 'mixed' && (
          <div className="source-switch" role="group" aria-label="List source">
            <button type="button" className={source === 'curated' ? 'active' : ''} onClick={() => onSource('curated')}>Curated</button>
            <button type="button" className={source === 'built' ? 'active' : ''} onClick={() => onSource('built')}>Built</button>
          </div>
        )}
        <button type="button" className="icon-button" onClick={onSearch} title="Search (Ctrl/⌘ K)" aria-label="Search">⌕</button>
        <button type="button" className="button" onClick={onPractice}>Practice</button>
        <button type="button" className="icon-button" onClick={onImport} title="Import a word list" aria-label="Import">⇧</button>
        <button type="button" className="icon-button" onClick={onCredits} title="Credits and licenses" aria-label="Credits">i</button>
        <button type="button" className="icon-button" onClick={onSettings} title="Settings" aria-label="Settings">⚙</button>
        {reviewCount > 0 && <span className="review-badge" title="Review words">{reviewCount}</span>}
      </div>
    </header>
  )
}
