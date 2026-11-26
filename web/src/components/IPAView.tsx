import { highlight } from '../lib/ipa'

export function IPAView({
  ipa,
  targets,
  kind,
  className = '',
}: {
  ipa: string
  targets: string[]
  kind: string
  className?: string
}) {
  const part = highlight(ipa, targets, kind)
  if (!part) return <span className={className}>{ipa}</span>
  return (
    <span className={className}>
      {part.prefix}
      <mark className="ipa-target">{part.hit}</mark>
      {part.suffix}
    </span>
  )
}
