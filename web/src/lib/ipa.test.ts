import { describe, expect, it } from 'vitest'
import { highlight, rowIPA } from './ipa'

describe('IPA highlighting', () => {
  it('handles the alveolar approximant spelling of r', () => {
    expect(highlight('/ˈɹaɪt/', ['r'], 'onset')).toEqual({ prefix: '/ˈ', hit: 'ɹ', suffix: 'aɪt/' })
  })
  it('highlights the final consonant for coda tiles', () => {
    expect(highlight('/ˈænd/', ['d'], 'coda')).toEqual({ prefix: '/ˈæn', hit: 'd', suffix: '/' })
  })
  it('prefers UK for compact rows', () => {
    expect(rowIPA({ word: '/wɝd/' }, { word: '/wɜːd/' }, 'word', 'both')).toBe('/wɜːd/')
  })
})
