import { useEffect, useId, useMemo, useState } from 'react'
import type { Articulation, MouthShape } from '../lib/types'

const W = 500
const H = 360

const restShape: MouthShape = {
  tip: 0.12, body: 0.18, back: 0.45, lipRound: 0, jaw: 0.16,
  contact: 'none', airflow: 'none', voiced: true,
}

function blend(a: MouthShape, b: MouthShape, t: number): MouthShape {
  return {
    tip: a.tip + (b.tip - a.tip) * t,
    body: a.body + (b.body - a.body) * t,
    back: a.back + (b.back - a.back) * t,
    lipRound: a.lipRound + (b.lipRound - a.lipRound) * t,
    jaw: a.jaw + (b.jaw - a.jaw) * t,
    contact: t < 0.5 ? a.contact : b.contact,
    airflow: t < 0.5 ? a.airflow : b.airflow,
    voiced: t < 0.5 ? a.voiced : b.voiced,
  }
}

function tongueGeometry(shape: MouthShape) {
  let tipX = 0.48 + shape.tip * 0.19
  let tipY = 0.74 - shape.tip * 0.30
  if (shape.contact === 'alveolar' && shape.airflow !== 'center') {
    tipX = 0.65
    tipY = 0.425
  } else if (shape.contact === 'betweenTeeth') {
    tipX = 0.80
    tipY = 0.52
  }
  const bodyX = 0.37 + shape.back * 0.12
  const bodyY = 0.74 - shape.body * 0.22
  return { tipX, tipY, bodyX, bodyY, jaw: shape.jaw * 0.04 }
}

function tonguePath(shape: MouthShape): string {
  const { tipX, tipY, bodyX, bodyY, jaw } = tongueGeometry(shape)
  const p = (x: number, y: number) => `${x * W} ${y * H}`
  return [
    `M ${p(0.24, 0.67 + jaw)}`,
    `C ${p(0.29, 0.57)} ${p(0.31, bodyY)} ${p(bodyX, bodyY)}`,
    `C ${p(bodyX + 0.10, bodyY - 0.04)} ${p(tipX - 0.09, tipY)} ${p(tipX, tipY)}`,
    `C ${p(tipX + 0.02, tipY + 0.10)} ${p(0.68, 0.70)} ${p(0.70, 0.77 + jaw)}`,
    `C ${p(0.50, 0.85)} ${p(0.30, 0.83)} ${p(0.24, 0.80 + jaw)}`,
    'Z',
  ].join(' ')
}

function contactPoint(contact: MouthShape['contact']): { x: number; y: number } | null {
  switch (contact) {
    case 'none': return null
    case 'lips': return { x: 0.81, y: 0.55 }
    case 'teeth': return { x: 0.73, y: 0.52 }
    case 'betweenTeeth': return { x: 0.82, y: 0.54 }
    case 'alveolar': return { x: 0.65, y: 0.41 }
    case 'postAlveolar': return { x: 0.59, y: 0.40 }
    case 'palatal': return { x: 0.49, y: 0.37 }
    case 'velar': return { x: 0.29, y: 0.39 }
    case 'glottal': return { x: 0.20, y: 0.82 }
  }
}

function useReducedMotion() {
  const [reduced, setReduced] = useState(false)
  useEffect(() => {
    const media = window.matchMedia('(prefers-reduced-motion: reduce)')
    setReduced(media.matches)
    const listener = () => setReduced(media.matches)
    media.addEventListener('change', listener)
    return () => media.removeEventListener('change', listener)
  }, [])
  return reduced
}

export function MouthDiagram({
  articulation,
  compact = false,
}: {
  articulation: Articulation
  compact?: boolean
}) {
  const [playing, setPlaying] = useState(false)
  const [phase, setPhase] = useState(1)
  const reduced = useReducedMotion()
  const gradientId = useId().replaceAll(':', '')

  useEffect(() => {
    if (!playing || reduced) {
      setPhase(1)
      return
    }
    let frame = 0
    const start = performance.now()
    const tick = (now: number) => {
      setPhase((Math.sin(((now - start) / 1000) * 1.5) + 1) / 2)
      frame = requestAnimationFrame(tick)
    }
    frame = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(frame)
  }, [playing, reduced])

  const from = articulation.glide ? articulation.shape : restShape
  const to = articulation.glide ?? articulation.shape
  const shape = blend(from, to, phase)
  const ghost = tonguePath(from)
  const tongue = tonguePath(shape)
  const tip = tongueGeometry(shape)
  const restTip = tongueGeometry(from)
  const jawDrop = shape.jaw * 0.04
  const lipWidth = 0.055 + shape.lipRound * 0.015
  const voiceColor = shape.voiced ? '#ffad40' : 'rgba(255,255,255,.25)'
  const target = contactPoint(shape.contact)

  const airflow = useMemo(() => {
    const blue = '#59c7ff'
    const style = {
      fill: 'none',
      stroke: blue,
      strokeWidth: compact ? 1.5 : 2,
      strokeLinecap: 'round' as const,
      strokeDasharray: '3 6',
      opacity: 0.82,
    }
    const p = (x: number, y: number) => `${x * W} ${y * H}`
    if (shape.airflow === 'center') {
      return <path d={`M ${p(0.22, 0.74)} L ${p(0.30, 0.62)} L ${p(0.46, 0.54)} L ${p(0.62, 0.50)} L ${p(0.80, 0.54)}`} {...style} />
    }
    if (shape.airflow === 'side') {
      return (
        <g>
          <path d={`M ${p(0.22, 0.74)} L ${p(0.30, 0.64)} L ${p(0.45, 0.66)} L ${p(0.60, 0.70)} L ${p(0.72, 0.70)}`} {...style} />
          <path d={`M ${p(0.24, 0.76)} L ${p(0.34, 0.68)} L ${p(0.50, 0.72)} L ${p(0.64, 0.75)}`} {...style} />
        </g>
      )
    }
    if (shape.airflow === 'nasal') {
      return <path d={`M ${p(0.22, 0.74)} C ${p(0.22, 0.60)} ${p(0.25, 0.50)} ${p(0.28, 0.44)} C ${p(0.40, 0.34)} ${p(0.55, 0.25)} ${p(0.70, 0.27)}`} {...style} />
    }
    if (shape.airflow === 'stop' && target) {
      return (
        <g>
          {[-0.035, 0, 0.035].map((offset) => (
            <line
              key={offset}
              x1={(target.x + offset) * W}
              y1={target.y * H}
              x2={(target.x + offset + 0.045) * W}
              y2={(target.y - 0.045) * H}
              {...style}
            />
          ))}
        </g>
      )
    }
    return null
  }, [shape.airflow, shape.contact, compact, target])

  const arrowDistance = Math.hypot((tip.tipX - restTip.tipX) * W, (tip.tipY - restTip.tipY) * H)
  const p = (x: number, y: number) => `${x * W} ${y * H}`
  const label = (text: string, at: [number, number], to: [number, number]) => (
    <g>
      <line x1={at[0] * W} y1={at[1] * H} x2={to[0] * W} y2={to[1] * H} stroke="rgba(255,255,255,.22)" strokeDasharray="2 2" strokeWidth=".8" />
      <text x={at[0] * W} y={at[1] * H} fill="rgba(255,255,255,.62)" fontSize="8" fontWeight="500" textAnchor="middle">{text}</text>
    </g>
  )

  return (
    <div className={`mouth-diagram ${compact ? 'compact' : ''}`}>
      <svg viewBox={`0 0 ${W} ${H}`} role="img" aria-label={`${articulation.name}. ${articulation.steps.join(' ')}`}>
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#f56c70" />
            <stop offset="1" stopColor="#b92e46" />
          </linearGradient>
        </defs>
        <rect width={W} height={H} rx={compact ? 10 : 16} fill="#151c27" />
        <path
          d={`M ${p(0.12, 0.20)} C ${p(0.20, 0.10)} ${p(0.40, 0.10)} ${p(0.55, 0.12)} C ${p(0.68, 0.14)} ${p(0.78, 0.20)} ${p(0.78, 0.30)} C ${p(0.81, 0.36)} ${p(0.85, 0.42)} ${p(0.85, 0.48)} C ${p(0.85, 0.55)} ${p(0.83, 0.61)} ${p(0.79, 0.64)} C ${p(0.75, 0.72)} ${p(0.70, 0.80)} ${p(0.62, 0.82)} C ${p(0.40, 0.90)} ${p(0.20, 0.92)} ${p(0.15, 0.90)} C ${p(0.05, 0.70)} ${p(0.05, 0.35)} ${p(0.12, 0.20)} Z`}
          fill="rgba(246,185,160,.14)"
          stroke="rgba(246,198,180,.20)"
        />
        <path
          d={`M ${p(0.80, 0.48)} C ${p(0.66, 0.35)} ${p(0.45, 0.34)} ${p(0.30, 0.42)} C ${p(0.23, 0.48)} ${p(0.18, 0.60)} ${p(0.20, 0.70)} C ${p(0.24, 0.78)} ${p(0.40, 0.80)} ${p(0.48, 0.80)} C ${p(0.66, 0.79)} ${p(0.79, 0.68)} ${p(0.81, 0.62)} Z`}
          fill="rgba(84,20,28,.92)"
        />
        <path
          d={`M ${p(0.23, 0.43)} C ${p(0.36, 0.37)} ${p(0.52, 0.38)} ${p(0.62, 0.405)} C ${p(0.68, 0.41)} ${p(0.78, 0.43)} ${p(0.80, 0.48)}`}
          fill="none"
          stroke="rgba(250,180,164,.75)"
          strokeWidth={compact ? 5 : 7}
          strokeLinecap="round"
        />
        <path
          d={`M ${p(0.30, 0.42)} C ${p(0.24, 0.45)} ${p(0.20, 0.50)} ${p(0.22, 0.55)}`}
          fill="none"
          stroke="rgba(235,158,158,.55)"
          strokeWidth={compact ? 4 : 6}
          strokeLinecap="round"
        />
        <path d={ghost} fill="none" stroke="rgba(255,255,255,.28)" strokeWidth="1.3" strokeDasharray="4 4" />
        <path d={tongue} fill={`url(#${gradientId})`} stroke="rgba(255,194,186,.55)" />
        {arrowDistance > W * 0.03 && (
          <g>
            <line
              x1={restTip.tipX * W}
              y1={restTip.tipY * H}
              x2={tip.tipX * W}
              y2={tip.tipY * H}
              stroke="rgba(255,255,255,.45)"
              strokeWidth="1.2"
              strokeDasharray="4 3"
            />
            <polygon
              points={`${tip.tipX * W},${tip.tipY * H} ${tip.tipX * W - 7},${tip.tipY * H - 4} ${tip.tipX * W - 4},${tip.tipY * H + 7}`}
              fill="rgba(255,255,255,.55)"
            />
          </g>
        )}
        <rect x={0.70 * W} y={0.445 * H} width={0.045 * W} height={0.055 * H} rx={4} fill="rgba(250,242,224,.9)" />
        <rect x={0.70 * W} y={(0.575 + jawDrop) * H} width={0.045 * W} height={0.045 * H} rx={4} fill="rgba(250,242,224,.9)" />
        <path
          d={`M ${p(0.76, 0.46)} C ${p(0.79, 0.44)} ${p(0.82, 0.46)} ${p(0.80 + lipWidth, 0.49)} C ${p(0.82, 0.52)} ${p(0.80, 0.53)} ${p(0.77, 0.53)} Z`}
          fill="rgba(219,87,107,.92)"
        />
        <path
          d={`M ${p(0.77, 0.57 + jawDrop)} C ${p(0.82, 0.57)} ${p(0.83, 0.59)} ${p(0.80 + lipWidth, 0.61 + jawDrop)} C ${p(0.79, 0.65)} ${p(0.78, 0.66)} ${p(0.75, 0.65 + jawDrop)} Z`}
          fill="rgba(188,64,87,.92)"
        />
        {airflow}
        <line x1={0.175 * W} y1={0.79 * H} x2={0.195 * W} y2={0.77 * H} stroke={voiceColor} strokeWidth="2" strokeLinecap="round" />
        <line x1={0.205 * W} y1={0.79 * H} x2={0.185 * W} y2={0.77 * H} stroke={voiceColor} strokeWidth="2" strokeLinecap="round" />
        {shape.voiced && (
          <circle cx={0.20 * W} cy={0.79 * H} r={7 + Math.sin(phase * Math.PI * 2) * 2} fill="none" stroke={voiceColor} strokeOpacity=".45" />
        )}
        {target && (
          <g>
            <circle cx={target.x * W} cy={target.y * H} r={7 + Math.sin(phase * Math.PI * 2) * 1.2} fill="none" stroke="#5cf28f" strokeWidth="2" />
            <circle cx={target.x * W} cy={target.y * H} r="1.5" fill="#5cf28f" />
          </g>
        )}
        {!compact && (
          <g>
            {label('ridge', [0.60, 0.28], [0.65, 0.405])}
            {label('tongue tip', [0.53, 0.22], [tip.tipX, tip.tipY])}
            {label('tongue body', [0.17, 0.56], [tip.bodyX, tip.bodyY])}
            {label('lips', [0.92, 0.52], [0.82, 0.55])}
            {label('vocal folds', [0.10, 0.86], [0.19, 0.79])}
          </g>
        )}
      </svg>
      {!compact && (
        <button type="button" className="diagram-play" onClick={() => setPlaying((value) => !value)}>
          {playing ? 'Pause' : 'Animate'}
        </button>
      )}
    </div>
  )
}
