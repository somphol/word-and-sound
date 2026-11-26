import type { MixedList } from '../lib/types'

export function MixedPanel({
  lists, selectedId, wordCount, onSelect, onImport,
}: {
  lists: MixedList[]
  selectedId: string
  wordCount: (list: MixedList) => number
  onSelect: (list: MixedList) => void
  onImport: () => void
}) {
  return (
    <section className="mixed-panel">
      <div className="panel-title">
        <div>
          <h2>Word lists</h2>
          <span>{lists.length} lists</span>
        </div>
        <button type="button" className="button small" onClick={onImport}>+ Import</button>
      </div>
      <div className="mixed-list">
        {lists.map((list) => (
          <button
            key={list.id}
            type="button"
            className={`mixed-card ${selectedId === list.id ? 'active' : ''}`}
            onClick={() => onSelect(list)}
          >
            <div>
              <strong>{list.title}</strong>
              <span>{wordCount(list)} words</span>
            </div>
            <p>{list.source}</p>
            <em>{list.license}</em>
          </button>
        ))}
      </div>
      <p className="muted-note">Imported lists and progress stay in this browser. Nothing is uploaded.</p>
    </section>
  )
}
