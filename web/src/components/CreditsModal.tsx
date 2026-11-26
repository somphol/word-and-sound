import type { Provenance } from '../lib/types'

export function CreditsModal({ provenance, onClose }: { provenance: Provenance; onClose: () => void }) {
  return (
    <div className="overlay" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <div className="modal credits-modal" role="dialog" aria-modal="true" aria-label="Credits">
        <header className="modal-head">
          <div><h2>Credits and licenses</h2><p>Word &amp; Sound {__APP_VERSION__} · code MIT · bundled data CC BY-SA 4.0</p></div>
          <button type="button" className="button small" onClick={onClose}>Close</button>
        </header>
        <p className="muted-note">The app code is MIT licensed. The bundled word lists, pronunciations and articulation guides are CC BY-SA 4.0. The data remains downloadable and reusable.</p>
        <div className="credits-list">
          {provenance.sources.map((source) => (
            <article key={source.name}>
              <h3>{source.name} <em>{source.license}</em></h3>
              {source.url && <a href={source.url} target="_blank" rel="noreferrer">{source.url}</a>}
              {source.note && <p>{source.note}</p>}
              {source.sha256 && <code>sha256 {source.sha256.slice(0, 16)}…</code>}
            </article>
          ))}
        </div>
        <p className="muted-note">Imported lists and microphone recordings are the user’s responsibility and never leave this browser.</p>
      </div>
    </div>
  )
}
