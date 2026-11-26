export const CATEGORIES = [
  ['starting', 'Starting'],
  ['vowel', 'Vowel'],
  ['ending', 'Ending'],
  ['mixed', 'Mixed'],
] as const

export function CategoryTabs({
  category,
  onCategory,
  className = '',
}: {
  category: string
  onCategory: (id: string) => void
  className?: string
}) {
  return (
    <nav className={`tabs ${className}`.trim()} aria-label="Sound categories">
      {CATEGORIES.map(([id, label]) => (
        <button key={id} type="button" className={category === id ? 'active' : ''} onClick={() => onCategory(id)}>
          {label}
        </button>
      ))}
    </nav>
  )
}
