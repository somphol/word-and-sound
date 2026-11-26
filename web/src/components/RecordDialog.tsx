import type { IpaPart } from '../lib/ipa'
import { useRecorder } from '../lib/recorder'

export function RecordDialog({
  word, parts, onPlay, onSlow, onClose,
}: {
  word: string
  parts: IpaPart[]
  onPlay: () => void
  onSlow: () => void
  onClose: () => void
}) {
  const recorder = useRecorder()
  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal record-modal" role="dialog" aria-modal="true" aria-label="Record and compare">
        <header className="modal-head">
          <div><h2>Record and compare</h2><p>Your recording stays in this browser.</p></div>
          <button type="button" className="button small" onClick={() => { recorder.reset(); onClose() }}>Close</button>
        </header>
        <div className="record-word">
          <strong>{word}</strong>
          {parts.map((part) => <span key={part.label}><em>{part.label}</em> {part.ipa}</span>)}
        </div>
        <div className="record-controls">
          <button type="button" className={`button ${recorder.recording ? 'danger' : 'primary'}`} onClick={() => recorder.recording ? recorder.stop() : void recorder.start()}>
            {recorder.recording ? 'Stop' : 'Record'}
          </button>
          {recorder.url && <button type="button" className="button" onClick={recorder.play}>Play mine</button>}
          {recorder.url && <button type="button" className="button small" onClick={recorder.reset}>Delete</button>}
          <span className="record-time">{recorder.elapsed.toFixed(1)} s</span>
        </div>
        <div className="record-controls">
          <button type="button" className="button small" onClick={onPlay}>Hear the model</button>
          <button type="button" className="button small" onClick={onSlow}>Slow model</button>
        </div>
        {recorder.error && <p className="warn">{recorder.error}</p>}
        <p className="muted-note">No score is calculated. Listen for one feature at a time: the target sound, stress, then the whole word.</p>
      </div>
    </div>
  )
}
