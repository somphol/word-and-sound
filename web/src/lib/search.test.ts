import { describe, expect, it } from 'vitest'
import type { AppData } from './types'
import { buildWordIndex, searchResults } from './search'

const data: AppData = {
  library: {
    app: { name: 't', tagline: '', dataLicense: '', codeLicense: '' },
    categories: [
      { id: 'starting', title: 'Starting Sound', tiles: [
        { id: 'startingTH', label: 'θ', exampleWord: 'think', listKey: 'th', group: 'single', kind: 'onset', targets: ['θ'] },
      ] },
      { id: 'vowel', title: 'Vowel', tiles: [] },
      { id: 'ending', title: 'Ending Sound', tiles: [] },
    ],
    mixed: [{ id: 'core', title: 'Core', source: 'Test', author: '', license: 'CC BY-SA 4.0', url: '' }],
    lists: { th: ['think', 'thing', 'thin'], core: ['think', 'the'] },
  },
  us: { think: '/θɪŋk/', thing: '/θɪŋ/', thin: '/θɪn/', the: '/ðə/' },
  uk: { think: '/θɪŋk/' },
  patterns: { source: '', license: '', limit: 120, lists: { startingTH: ['think', 'thing', 'thin'] } },
  pairs: { source: '', license: '', pairs: [] },
  articulation: [],
  provenance: { generated: '', dataLicense: '', codeLicense: '', sources: [] },
}

describe('search', () => {
  it('finds words by text and IPA', () => {
    const index = buildWordIndex(data, 'built', [])
    const words = searchResults('θ', 'all', data, index, {}, data.us, data.uk)
    expect(words.words.map((hit) => hit.word)).toContain('think')
    expect(searchResults('the', 'all', data, index, {}, data.us, data.uk).words[0].word).toBe('the')
  })
})
