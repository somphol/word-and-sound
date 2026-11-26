import type { Articulation } from '../lib/types'

export function VowelChart({
  articulation,
  all,
}: {
  articulation: Articulation
  all: Articulation[]
}) {
  const vowels = all.filter((item) => item.isVowel)
  const contrasts = new Set(articulation.contrasts)
  const x = (back: number) => 90 + back * 250
  const y = (body: number) => 25 + (1 - body) * 100

  return (
    <div className="vowel-chart">
      <svg viewBox="0 0 420 150" role="img" aria-label={`Vowel space. Target ${articulation.symbol}.`}>
        <rect x="1" y="1" width="418" height="148" rx="10" fill="var(--diagram-bg)" stroke="var(--diagram-line)" />
        <path d="M 90 25 L 340 25 L 340 125 L 90 125 Z" fill="none" stroke="var(--diagram-line)" strokeDasharray="4 4" />
        {vowels.map((vowel) => {
          const isTarget = vowel.id === articulation.id
          const isContrast = contrasts.has(vowel.id)
          return (
            <g key={vowel.id}>
              <circle
                cx={x(vowel.shape.back)}
                cy={y(vowel.shape.body)}
                r={isTarget ? 6 : isContrast ? 4 : 2.5}
                fill={isTarget ? 'var(--accent)' : isContrast ? 'var(--orange)' : 'rgba(255,255,255,.35)'}
              />
              {(isTarget || isContrast) && (
                <text x={x(vowel.shape.back) + 10} y={y(vowel.shape.body) + 3} fontSize={isTarget ? 11 : 9} fontWeight={isTarget ? 700 : 400} fill={isTarget ? 'var(--accent)' : 'var(--orange)'}>
                  {vowel.symbol}
                </text>
              )}
            </g>
          )
        })}
        <text x="90" y="141" fontSize="8" fill="var(--diagram-label)" textAnchor="middle">front</text>
        <text x="340" y="141" fontSize="8" fill="var(--diagram-label)" textAnchor="middle">back</text>
        <text x="78" y="28" fontSize="8" fill="var(--diagram-label)" textAnchor="end">high</text>
        <text x="78" y="125" fontSize="8" fill="var(--diagram-label)" textAnchor="end">low</text>
      </svg>
    </div>
  )
}
