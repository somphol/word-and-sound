import { useEffect, useMemo, useRef, useState } from 'react'
import type { AppData, MixedList, SearchFilter, WordHit, WordProgress } from '../lib/types'
import { searchResults } from '../lib/search'
import { rowIPA } from '../lib/ipa'
import { IPAView } from './IPAView'

export function SearchPalette({
  data, index, progress, lists, wordCount, onClose, onTile, onList, onWord,
}: {
  data: AppData
  index: Map<string, WordHit>
  progress: Record<string, WordProgress>
  lists: MixedList[]
  wordCount: (list: MixedList) => number
  onClose: () => void
  onTile: (tile: AppData['library']['categories'][number]['tiles'][number]) => void
  onList: (list: MixedList) => void
  onWord: (hit: WordHit) => void
}) {
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<SearchFilter>('all')
  const input = useRef<HTMLInputElement>(null)
  const results = useMemo(
    () => searchResults(query, filter, data, index, progress, data.us, data.uk),
    [query, filter, data, index, progress],
  )
  const listHits = useMemo(() => {
    const value = query.trim().toLowerCase()
    return lists.filter((list) => !value || list.title.toLowerCase().includes(value) || list.source.toLowerCase().includes(value)).slice(0, 12)
  }, [lists, query])

  useEffect(() => {
    input.current?.focus()
  }, [])

  const first = results.tiles[0] ?? listHits[0] ?? results.words[0]
  const openFirst = () => {
    if (results.tiles[0]) onTile(results.tiles[0])
    else if (listHits[0]) onList(listHits[0])
    else if (results.words[0]) onWord(results.words[0])
  }

  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal search-modal" role="dialog" aria-modal="true" aria-label="Search">
        <div className="search-bar">
          <span>⌕</span>
          <input
            ref={input}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Escape') onClose()
              if (event.key === 'Enter') openFirst()
            }}
            placeholder="Search words, sounds, lists or IPA"
            aria-label="Search words, sounds, lists or IPA"
          />
          <div className="filter-switch">
            {(['all', 'favorites', 'trouble', 'due'] as SearchFilter[]).map((value) => (
              <button key={value} type="button" className={filter === value ? 'active' : ''} onClick={() => setFilter(value)}>
                {value === 'all' ? 'All' : value === 'favorites' ? 'Favorites' : value === 'trouble' ? 'Trouble' : 'Due'}
              </button>
            ))}
          </div>
          <button type="button" className="button small" onClick={onClose}>Close</button>
        </div>
        <div className="search-results">
          {!first && <p className="empty-words">No matches. Try a word, a sound such as θ, a list name, or an IPA symbol.</p>}
          {results.tiles.length > 0 && <h3>Sounds</h3>}
          {results.tiles.map((tile) => (
            <button key={tile.id} type="button" className="result-row" onClick={() => onTile(tile)}>
              <strong className="result-symbol">{tile.label}</strong>
              <span><b>{tile.exampleWord}</b><em>{data.library.categories.find((group) => group.tiles.includes(tile))?.title} · {tile.group}</em></span>
              <small>›</small>
            </button>
          ))}
          {listHits.length > 0 && <h3>Lists</h3>}
          {listHits.map((list) => (
            <button key={list.id} type="button" className="result-row" onClick={() => onList(list)}>
              <strong className="result-symbol">≡</strong>
              <span><b>{list.title}</b><em>{list.source}</em></span>
              <small>{wordCount(list)} words</small>
            </button>
          ))}
          {results.words.length > 0 && <h3>Words · {results.words.length}</h3>}
          {results.words.map((hit) => (
            <button key={hit.id} type="button" className="result-row" onClick={() => onWord(hit)}>
              <strong>{hit.word}</strong>
              <span className="result-ipa">
                <IPAView ipa={rowIPA(data.us, data.uk, hit.word, 'both')} targets={[]} kind="onset" />
              </span>
              <small>{hit.listTitle}</small>
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
