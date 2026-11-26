import { describe, expect, it } from 'vitest'
import { spokenWord } from './pronounce'

describe('spoken words', () => {
  it('respells consonant-only interjections', () => {
    expect(spokenWord('hmph')).toBe('humph')
    expect(spokenWord('HMPH')).toBe('humph')
    expect(spokenWord('tsk')).toBe('tisk')
    expect(spokenWord('mph')).toBe('miles per hour')
  })
  it('expands honorifics and leaves normal words alone', () => {
    expect(spokenWord('Mr')).toBe('mister')
    expect(spokenWord('different')).toBe('different')
    expect(spokenWord("don't")).toBe("don't")
  })
})
