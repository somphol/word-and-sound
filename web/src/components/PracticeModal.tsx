import { useMemo, useState } from 'react'
import type { IpaMode, MinimalPair } from '../lib/types'
import { ipaParts } from '../lib/ipa'
import { IPAView } from './IPAView'

export function PracticeModal({
  pairs, us, uk, ipaMode, onClose, onPlay, onQuiz,
}: {
  pairs: MinimalPair[]
  us: Record<string, string>
  uk: Record<string, string>
  ipaMode: IpaMode
  onClose: () => void
  onPlay: (word: string, slow?: boolean) => void
  onQuiz: (word: string, correct: boolean) => void
}) {
  const [pairID, setPairID] = useState(pairs[0]?.id ?? '')
  const [mode, setMode] = useState<'listen' | 'quiz'>('listen')
  const [question, setQuestion] = useState<'a' | 'b' | null>(null)
  const [feedback, setFeedback] = useState<boolean | null>(null)
  const [correct, setCorrect] = useState(0)
  const [attempts, setAttempts] = useState(0)
  const pair = useMemo(() => pairs.find((item) => item.id === pairID) ?? pairs[0], [pairs, pairID])

  const reset = () => { setQuestion(null); setFeedback(null) }
  const playRandom = () => {
    const side = Math.random() < 0.5 ? 'a' : 'b'
    setQuestion(side)
    setFeedback(null)
    onPlay(side === 'a' ? pair.a : pair.b)
  }
  const answer = (side: 'a' | 'b') => {
    if (!question) return
    const right = side === question
    setFeedback(right)
    setAttempts((value) => value + 1)
    if (right) setCorrect((value) => value + 1)
    onQuiz(question === 'a' ? pair.a : pair.b, right)
  }
  const next = () => {
    const index = pairs.findIndex((item) => item.id === pair.id)
    setPairID(pairs[(index + 1) % pairs.length].id)
    reset()
  }
  if (!pair) return null

  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal practice-modal" role="dialog" aria-modal="true" aria-label="Minimal pairs">
        <header className="modal-head">
          <div><h2>Minimal pairs</h2><p>Hear the difference, then choose.</p></div>
          <select value={pairID} onChange={(event) => { setPairID(event.target.value); reset() }}>
            {pairs.map((item) => <option key={item.id} value={item.id}>{item.a} / {item.b}</option>)}
          </select>
          <div className="filter-switch">
            <button type="button" className={mode === 'listen' ? 'active' : ''} onClick={() => { setMode('listen'); reset() }}>Listen</button>
            <button type="button" className={mode === 'quiz' ? 'active' : ''} onClick={() => { setMode('quiz'); reset() }}>Quiz</button>
          </div>
          <button type="button" className="button small" onClick={onClose}>Close</button>
        </header>
        <div className="focus-badge">{pair.focus}</div>
        <div className="pair-cards">
          {(['a', 'b'] as const).map((side) => {
            const word = pair[side]
            const selected = question === side
            return (
              <div key={side} className={`pair-card ${feedback !== null && selected ? (feedback ? 'correct' : 'wrong') : ''}`}>
                <small>{side.toUpperCase()}</small>
                <strong>{word}</strong>
                <span className="pair-ipa">
                  {ipaParts(us, uk, word, ipaMode).map((part) => (
                    <span key={part.label}><em>{part.label}</em><IPAView ipa={part.ipa} targets={[]} kind="onset" /></span>
                  ))}
                </span>
                <button type="button" className="button small" onClick={() => onPlay(word)}>Play {side.toUpperCase()}</button>
                {mode === 'listen' && <button type="button" className="text-button" onClick={() => onPlay(word, true)}>slow</button>}
              </div>
            )
          })}
        </div>
        {mode === 'listen' ? (
          <p className="muted-note">Listen to both words, then repeat them aloud. IPA is a reference, not a score.</p>
        ) : (
          <div className="quiz-panel">
            <button type="button" className="button primary" onClick={playRandom}>Play one word</button>
            {question && <p>Which word did you hear?</p>}
            {question && (
              <div className="quiz-answers">
                <button type="button" className="button" disabled={feedback !== null} onClick={() => answer('a')}>A · {pair.a}</button>
                <button type="button" className="button" disabled={feedback !== null} onClick={() => answer('b')}>B · {pair.b}</button>
              </div>
            )}
            {feedback !== null && <strong className={feedback ? 'ok' : 'try'}>{feedback ? 'Correct' : 'Try again'}</strong>}
            <div className="quiz-footer"><span>Score: {correct} / {attempts}</span><button type="button" className="text-button" onClick={next}>Next pair ›</button></div>
          </div>
        )}
      </div>
    </div>
  )
}
