import { describe, expect, it } from 'vitest'
import { clampTextScale, clampWordScale, isDue, nextDue, nextStep, parseWordList, reviewWords } from './progress'
import type { WordProgress } from './types'

const item = (overrides: Partial<WordProgress> = {}): WordProgress => ({
  word: 'test', listens: 0, correct: 0, wrong: 0, step: 0, due: null,
  favorite: false, trouble: false, lastSeen: null, ...overrides,
})

describe('word list parser', () => {
  it('cleans, deduplicates and keeps the first line', () => {
    expect(parseWordList("word\nbass1\n2\nn't\ncat,ipa\ncat")).toEqual(['word', 'bass', 'cat'])
  })
  it('skips a CSV header', () => {
    expect(parseWordList('word,ipa\nthink,/θɪŋk/\n')).toEqual(['think'])
  })
  it('rejects phrases and punctuation', () => {
    expect(parseWordList('ice cream\nhello!\nok\npier\'s')).toEqual(['ok', "pier's"])
  })
})

describe('review scheduler', () => {
  it('advances and resets', () => {
    expect(nextStep(0, true)).toBe(1)
    expect(nextStep(4, true)).toBe(4)
    expect(nextStep(2, false)).toBe(0)
  })
  it('computes due dates', () => {
    const start = 1_700_000_000_000
    expect(nextDue(2, start) - start).toBe(7 * 86_400_000)
    expect(isDue(start - 1, start)).toBe(true)
    expect(isDue(start + 1, start)).toBe(false)
  })
  it('collects favorites, trouble and due words', () => {
    const progress = {
      a: item({ word: 'a', favorite: true }),
      b: item({ word: 'b', trouble: true }),
      c: item({ word: 'c', due: 1 }),
      d: item({ word: 'd', due: Date.now() + 10_000 }),
    }
    expect(reviewWords(progress, 1000)).toEqual(['c', 'a', 'b'])
  })
})

describe('display scale', () => {
  it('clamps text size between 90% and 130%', () => {
    expect(clampTextScale(0.5)).toBe(0.9)
    expect(clampTextScale(1.72)).toBe(1.3)
  })
  it('clamps word size between 100% and 160%', () => {
    expect(clampWordScale(0.2)).toBe(1)
    expect(clampWordScale(9)).toBe(1.6)
  })
})
