import type { AppData, ImportedList, SearchFilter, SearchResults, WordHit, WordProgress } from './types'
import { allTiles, wordsForTile } from './data'
import { isDue } from './progress'

export function buildWordIndex(
  data: AppData,
  source: 'curated' | 'built',
  imported: ImportedList[],
): Map<string, WordHit> {
  const index = new Map<string, WordHit>()
  for (const category of data.library.categories) {
    for (const tile of category.tiles) {
      const words = wordsForTile(data, tile, source)
      const title = `${category.title} · ${tile.label}`
      words.forEach((word, position) => {
        const key = word.toLowerCase()
        if (!index.has(key)) {
          index.set(key, {
            id: key,
            word,
            listID: tile.id,
            tileID: tile.id,
            listTitle: title,
            index: position,
          })
        }
      })
    }
  }
  const mixed = [...data.library.mixed, ...imported.map((list) => ({
    id: list.id, title: list.title, source: 'Imported', author: 'You', license: 'Your own content', url: '',
  }))]
  for (const list of mixed) {
    const words = imported.find((item) => item.id === list.id)?.words ?? data.library.lists[list.id] ?? []
    words.forEach((word, position) => {
      const key = word.toLowerCase()
      if (!index.has(key)) {
        index.set(key, {
          id: key,
          word,
          listID: list.id,
          tileID: null,
          listTitle: list.title,
          index: position,
        })
      }
    })
  }
  return index
}

export function searchResults(
  query: string,
  filter: SearchFilter,
  data: AppData,
  index: Map<string, WordHit>,
  progress: Record<string, WordProgress>,
  us: Record<string, string>,
  uk: Record<string, string>,
): SearchResults {
  const trimmed = query.trim()
  const matches = (value: string) => trimmed === '' || value.toLocaleLowerCase().includes(trimmed.toLocaleLowerCase())
  const results: SearchResults = { tiles: [], lists: [], words: [] }
  results.tiles = allTiles(data.library)
    .filter((tile) => matches(tile.label) || matches(tile.exampleWord))
    .slice(0, 24)
  results.lists = [...data.library.mixed]
    .filter((list) => matches(list.title) || matches(list.source))
    .slice(0, 12)
  if (!trimmed) return results

  const now = Date.now()
  const hits: Array<{ rank: number; hit: WordHit }> = []
  for (const hit of index.values()) {
    const item = progress[hit.word.toLowerCase()]
    if (filter === 'favorites' && !item?.favorite) continue
    if (filter === 'trouble' && !item?.trouble) continue
    if (filter === 'due' && !isDue(item?.due ?? null, now)) continue
    const word = hit.word
    const ipa = `${us[word.toLowerCase()] ?? ''} ${uk[word.toLowerCase()] ?? ''}`
    let rank: number
    if (word.toLowerCase() === trimmed.toLowerCase()) rank = 0
    else if (word.toLowerCase().startsWith(trimmed.toLowerCase())) rank = 1
    else if (word.toLowerCase().includes(trimmed.toLowerCase())) rank = 2
    else if (ipa.includes(trimmed)) rank = 3
    else continue
    hits.push({ rank, hit })
  }
  hits.sort((a, b) => a.rank === b.rank ? a.hit.word.localeCompare(b.hit.word) : a.rank - b.rank)
  results.words = hits.slice(0, 80).map((entry) => entry.hit)
  return results
}
