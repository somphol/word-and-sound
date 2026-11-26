import { useEffect, useMemo, useRef, useState } from 'react'
import type { AppData, WordProgress } from '../lib/types'
import { rowIPA } from '../lib/ipa'
import { Icon } from './Icon'
import { IPAView } from './IPAView'

const ROW_HEIGHT = 48

export function WordPanel({
  data, title, words, currentIndex, searchText, onSearchChange, practised, progress,
  targets, kind, ipaMode, onSelect, onFavorite, onTrouble, onClose, onReview, reviewCount,
}: {
  data: AppData
  title: string
  words: string[]
  currentIndex: number
  searchText: string
  onSearchChange: (value: string) => void
  practised: number
  progress: Record<string, WordProgress>
  targets: string[]
  kind: string
  ipaMode: 'both' | 'us' | 'uk'
  onSelect: (index: number) => void
  onFavorite: (word: string) => void
  onTrouble: (word: string) => void
  onClose?: () => void
  onReview?: () => void
  reviewCount?: number
}) {
  const viewport = useRef<HTMLDivElement>(null)
  const [scrollTop, setScrollTop] = useState(0)
  const [height, setHeight] = useState(600)

  useEffect(() => {
    if (!viewport.current) return
    const observer = new ResizeObserver(([entry]) => setHeight(entry.contentRect.height))
    observer.observe(viewport.current)
    return () => observer.disconnect()
  }, [])

  const filtered = useMemo(() => {
    const query = searchText.trim().toLowerCase()
    return words
      .map((word, index) => ({ word, index }))
      .filter((entry) => !query || entry.word.toLowerCase().includes(query))
  }, [words, searchText])

  useEffect(() => {
    if (searchText) {
      viewport.current?.scrollTo({ top: 0 })
      setScrollTop(0)
      return
    }
    if (!viewport.current) return
    const top = currentIndex * ROW_HEIGHT
    const visibleTop = viewport.current.scrollTop
    if (top < visibleTop || top > visibleTop + height - ROW_HEIGHT) {
      viewport.current.scrollTo({ top: Math.max(0, top - height / 2), behavior: 'smooth' })
    }
  }, [currentIndex, height, searchText])

  const start = Math.max(0, Math.floor(scrollTop / ROW_HEIGHT) - 4)
  const end = Math.min(filtered.length, start + Math.ceil(height / ROW_HEIGHT) + 8)

  return (
    <section className="word-panel">
      <header className="word-panel-head">
        <div className="word-panel-title">
          <h2>{title}</h2>
          <span>{words.length} words · {practised} practised</span>
        </div>
        {onReview && (reviewCount ?? 0) > 0 && (
          <button type="button" className="review-jump" onClick={onReview}>
            Review <span>{reviewCount}</span>
          </button>
        )}
        <span className="counter">{words.length ? `${currentIndex + 1} / ${words.length}` : ''}</span>
        {onClose && (
          <button type="button" className="icon-button" onClick={onClose} aria-label="Close word list">
            <Icon name="close" />
          </button>
        )}
      </header>
      <label className="search-field">
        <Icon name="search" size={16} />
        <input
          value={searchText}
          onChange={(event) => onSearchChange(event.target.value)}
          placeholder="Search this list"
          aria-label="Search this list"
        />
        {searchText && (
          <button type="button" onClick={() => onSearchChange('')} aria-label="Clear search">
            <Icon name="close" size={14} />
          </button>
        )}
      </label>
      <div
        className="word-scroll"
        ref={viewport}
        onScroll={(event) => setScrollTop(event.currentTarget.scrollTop)}
      >
        <div style={{ height: filtered.length * ROW_HEIGHT, position: 'relative' }}>
          {filtered.slice(start, end).map((entry, offset) => {
            const item = progress[entry.word.toLowerCase()]
            const current = entry.index === currentIndex
            return (
              <div
                key={`${entry.word}-${entry.index}`}
                className={`word-row ${current ? 'current' : ''}`}
                style={{ top: (start + offset) * ROW_HEIGHT, height: ROW_HEIGHT }}
                onClick={() => onSelect(entry.index)}
                role="button"
                tabIndex={0}
                onKeyDown={(event) => event.key === 'Enter' && onSelect(entry.index)}
              >
                <span className="row-number">{entry.index + 1}</span>
                <span className="row-word">{entry.word}</span>
                <span className="row-ipa">
                  <IPAView ipa={rowIPA(data.us, data.uk, entry.word, ipaMode)} targets={targets} kind={kind} />
                </span>
                <span className="row-actions">
                  <button
                    type="button"
                    className={`row-action star ${item?.favorite ? 'on' : ''}`}
                    aria-label={item?.favorite ? 'Remove from favorites' : 'Add to favorites'}
                    aria-pressed={!!item?.favorite}
                    onClick={(event) => { event.stopPropagation(); onFavorite(entry.word) }}
                  >
                    <Icon name="star" size={15} filled={!!item?.favorite} />
                  </button>
                  <button
                    type="button"
                    className={`row-action flag ${item?.trouble ? 'on' : ''}`}
                    aria-label={item?.trouble ? 'Clear difficult mark' : 'Mark as difficult'}
                    aria-pressed={!!item?.trouble}
                    onClick={(event) => { event.stopPropagation(); onTrouble(entry.word) }}
                  >
                    <Icon name="flag" size={15} filled={!!item?.trouble} />
                  </button>
                </span>
              </div>
            )
          })}
        </div>
        {!filtered.length && <p className="empty-words">No matching words.</p>}
      </div>
    </section>
  )
}
